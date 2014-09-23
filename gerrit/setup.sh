#!/bin/sh -e
#
# Initialize Gerrit data
#
# Assume the current directory (set by WORKDIR in Dockerfile)
# is Gerrit installation directory.
#

# Expected environment variables
echo "Test environment configuration..."
[ -f bin/gerrit.sh ]
[ -d "$TMP" ]
[ -d "$gerrit_save_dir" ]
[ $(id -u) -eq 0 ]
echo "Succeeded"

gerrit_home=$(pwd)
user=gerrit

# Upgrade actions
if [ -d git/All-Projects.git ]; then
su $user -c "sh -sex" <<_UPGRADE
# Gerrit 2.9 (see https://gerrit-documentation.storage.googleapis.com/ReleaseNotes/ReleaseNotes-2.9.html#_important_notes)
java -jar bin/gerrit.war init -d .
java -jar bin/gerrit.war reindex -d . --recheck-mergeable
_UPGRADE
exit 0
fi


# The following steps are for initial bootstrapping only

# Restore archived Gerrit data.
#
jenkins_key=`cat "$gerrit_save_dir/jenkins_id_rsa.pub"`
chown $user data db git
su $user -c "sh -sex" <<_RESTORE
cd "$gerrit_save_dir"
cp -pr data db git "$gerrit_home"
rm -rf "$gerrit_save_dir"
_RESTORE


# Create administrative Gerrit account
#
uid=1
email="admin@gerrit"
key=`cat etc/ssh_host_rsa_key.pub`
su $user -c "sh -sex" <<_ADMIN
java -jar bin/gerrit.war gsql <<_ADMIN_ACCOUNT
INSERT INTO ACCOUNTS (FULL_NAME, REGISTERED_ON, ACCOUNT_ID)
    VALUES ('Gerrit Administrator', now(), $uid);
INSERT INTO ACCOUNT_EXTERNAL_IDS (ACCOUNT_ID, EXTERNAL_ID)
    VALUES ($uid, 'username:admin');
INSERT INTO ACCOUNT_EXTERNAL_IDS (ACCOUNT_ID, EMAIL_ADDRESS, EXTERNAL_ID)
    VALUES ($uid, '$email', 'mailto:$email');
INSERT INTO ACCOUNT_GROUP_MEMBERS (ACCOUNT_ID, GROUP_ID)
    VALUES ($uid, 1);
INSERT INTO ACCOUNT_SSH_KEYS (ACCOUNT_ID, SEQ, SSH_PUBLIC_KEY, VALID)
    VALUES ($uid, 1, '$key', 'Y');
_ADMIN_ACCOUNT

[ -d ~/.ssh ] || mkdir ~/.ssh
cat >~/.ssh/config <<_SSH_CONFIG
Host localhost
NoHostAuthenticationForLocalhost yes
IdentityFile $gerrit_home/etc/ssh_host_rsa_key
_SSH_CONFIG

git config --global user.email "$email"
_ADMIN


# Start Gerrit daemon so the remaining configuration may be done via Gerrit API
#
bin/gerrit.sh start

git_port=29418
git_user=admin
git_url="ssh://${git_user}@localhost:${git_port}"
config="git config -f project.config"


# Default configuration for All-Projects
#
su $user -c "sh -sex" <<_ALL_PROJECTS
cd "$TMP"
git clone -q "$git_url/All-Projects"
cd All-Projects

# Add Verified label applicable to regular branches only
$config         label.Verified.branch                   "refs/heads/*"
$config         label.Verified.function                 MaxWithBlock
$config --replace-all label.Verified.value              "-1 Fails"
$config --add   label.Verified.value                    "0 No score"
$config --add   label.Verified.value                    "+1 Verified"
git commit -q -a -m "Add Verified label"

# Make Code-Review label sticky
$config label.Code-Review.copyAllScoresOnTrivialRebase true
$config label.Code-Review.copyAllScoresIfNoCodeChange true
git commit -q -a -m "Make Code-Review label sticky on trivial changes"

# Access configuration - Non interactive users
$config --add   access."refs/*".read                    "group Non-Interactive Users"
$config --add   access."refs/heads/*".create            "group Non-Interactive Users"
$config --add   access."refs/heads/*".push              "group Non-Interactive Users"
$config --add   access."refs/heads/*".label-Code-Review "-1..+1 group Non-Interactive Users"
$config --add   access."refs/heads/*".label-Verified    "-1..+1 group Administrators"
$config --add   access."refs/heads/*".label-Verified    "-1..+1 group Non-Interactive Users"
$config --add   access."refs/tags/*".pushTag            "group Non-Interactive Users"
$config --add   access."refs/tags/*".pushSignedTag      "group Non-Interactive Users"
git commit -q -a -m "Add access for robots"

# Access configuration - Anonymous access
sed -i '/^global:Anonymous-Users/d' groups
$config --unset access."refs/*".read                    "group Anonymous Users" || [ \$? -eq 5 ]
$config --add   access."refs/*".read                    "group Project Owners"
git commit -q -a -m "Remove anonymous access"

git push -q origin HEAD:refs/meta/config
cd ..
rm -rf All-Projects
_ALL_PROJECTS


# Create and configure Open-Projects template project
#
su $user -c "sh -sex" <<_OPEN_PROJECTS
ssh -p $git_port $git_user@localhost gerrit create-project \
    --parent All-Projects \
    --permissions-only \
    --description "'Access configuration for open to everyone projects'" \
    Open-Projects

cd "$TMP"
git clone -q "$git_url/Open-Projects"
cd Open-Projects

# Access configuration
echo 'global:Registered-Users                 	Registered Users' >groups
git add groups
$config --add   access."refs/*".owner                   "group Registered Users"
git commit -q -a -m "Initial access configuration"

git push -q origin HEAD:refs/meta/config

cd ..
rm -rf Open-Projects
_OPEN_PROJECTS


# Create and configure Private-Projects template project
#
su $user -c "sh -sex" <<_PRIVATE_PROJECTS
ssh -p $git_port $git_user@localhost gerrit create-project \
    --parent All-Projects \
    --permissions-only \
    --description "'Access configuration for private projects'" \
    Private-Projects
_PRIVATE_PROJECTS


# Create account for Jenkins
#
su $user -c "sh -sex" <<_JENKINS_USER
ssh -p $git_port $git_user@localhost gerrit create-account \
    --ssh-key "'$jenkins_key'" \
    --group "'Non-Interactive Users'" \
    --full-name "'Jenkins CI'" \
    --email jenkins@cisandbox.asf.griddynamics.com \
    jenkins
_JENKINS_USER


# All done - stop Gerrit
#
bin/gerrit.sh stop

