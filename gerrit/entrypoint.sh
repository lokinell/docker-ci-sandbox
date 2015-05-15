#!/bin/sh -e
#
# Docker container ENTRYPOINT for gerrit
# Initializes Gerrit configuration, permissions and template projects.
#


# Assume the current directory (set by WORKDIR in Dockerfile)
# is Gerrit installation directory.
#
gerrit_home=$(pwd)
eval "HOME=~$(id -un)"
export HOME

# Expected environment variables
# to be passed from Docker command line, Dockerfile or fig.yml:
#
echo "Test environment configuration..."
[ -f bin/gerrit.sh ]
[ -d "$TMP" ]
echo "Succeeded"


# Upgrade actions
# Run upgrade actions if a marker file does not exist in container filesystem
#
if [ ! -f etc/upgraded ]; then
    # Gerrit 2.9, 2.10 (https://gerrit-documentation.storage.googleapis.com/ReleaseNotes/ReleaseNotes-2.10.html#_important_notes)
    java -jar bin/gerrit.war init -d .
    # Gerrit 2.9, 2.11 (see https://gerrit-documentation.storage.googleapis.com/ReleaseNotes/ReleaseNotes-2.9.html#_important_notes)
    java -jar bin/gerrit.war reindex -d .
    # Drop unused objects (upgrade to 2.10)
    echo "ALTER TABLE accounts DROP COLUMN show_user_in_review;" \
        | java -jar bin/gerrit.war gsql
    touch etc/upgraded
fi

[ ! -f /var/lock/initialized ] || exec "$@"


# The following steps are for initial bootstrapping only


# Create administrative Gerrit account
#
uid=1
email="admin@gerrit"
key=`cat etc/ssh_host_rsa_key.pub`
java -jar bin/gerrit.war gsql <<_ADMIN_ACCOUNT
INSERT INTO ACCOUNTS (FULL_NAME, REGISTERED_ON, ACCOUNT_ID)
    VALUES ('Gerrit Administrator', now(), $uid);
INSERT INTO ACCOUNT_EXTERNAL_IDS (ACCOUNT_ID, EXTERNAL_ID)
    VALUES ($uid, 'username:admin');
INSERT INTO ACCOUNT_EXTERNAL_IDS (ACCOUNT_ID, EXTERNAL_ID)
    VALUES ($uid, 'gerrit:admin');
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


# Start Gerrit daemon so the remaining configuration may be done via Gerrit API
#
bin/gerrit.sh start

git_port=29418
git_user=admin
git_url="ssh://${git_user}@localhost:${git_port}"
config="git config -f project.config"


# Default configuration for All-Projects
#
(
    cd "$TMP"
    mkdir checkout
    cd checkout
    git init -q
    git remote add origin "$git_url/All-Projects"
    git fetch -q origin refs/meta/config
    git checkout -q FETCH_HEAD

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
    $config --unset access."refs/*".read                    "group Anonymous Users" || [ $? -eq 5 ]
    $config --add   access."refs/*".read                    "group Project Owners"
    git commit -q -a -m "Remove anonymous access"

    # Access configuration - project creation
    $config --add   capability.createProject                "group Registered Users"
    git commit -q -a -m "Allow everyone to create projects"

    git push -q origin HEAD:refs/meta/config
    cd ..
    rm -rf checkout
)


# Create and configure Open-Projects template project
#
ssh -p $git_port $git_user@localhost gerrit create-project \
    --parent All-Projects \
    --permissions-only \
    --description "'Access configuration for open to everyone projects'" \
    Open-Projects

(
    cd "$TMP"
    mkdir checkout
    cd checkout
    git init -q
    git remote add origin "$git_url/Open-Projects"
    git fetch -q origin refs/meta/config
    git checkout -q FETCH_HEAD

    # Access configuration
    echo 'global:Registered-Users                 	Registered Users' >groups
    git add groups
    $config --add   access."refs/*".owner                   "group Registered Users"
    git commit -q -a -m "Initial access configuration"

    git push -q origin HEAD:refs/meta/config
    cd ..
    rm -rf checkout
)


# Create and configure Private-Projects template project
#
ssh -p $git_port $git_user@localhost gerrit create-project \
    --parent All-Projects \
    --permissions-only \
    --description "'Access configuration for private projects'" \
    Private-Projects


# Create account, groups.
#
# Jenkins account
jenkins_key=`cat "$gerrit_home/etc/jenkins_id_rsa.pub"`
jenkinsslave_key=`cat "$gerrit_home/etc/jenkinsslave_id_rsa.pub"`
ssh -p $git_port $git_user@localhost gerrit create-account \
    --ssh-key "'$jenkins_key'" \
    --group "'Non-Interactive Users'" \
    --full-name "'Jenkins CI'" \
    --email jenkins-bot@cisandbox.asf.griddynamics.com \
    jenkins-bot
ssh -p $git_port $git_user@localhost gerrit set-account \
    --add-ssh-key "'$jenkinsslave_key'" \
    jenkins-bot


# All done - stop Gerrit
#
bin/gerrit.sh stop


# Map LDAP groups to Gerrit groups.
# It's a workaround as "gerrit set-members" seems not working with LDAP groups.
#
java -jar bin/gerrit.war gsql <<_SQL
INSERT INTO ACCOUNT_GROUP_BY_ID (GROUP_ID, INCLUDE_UUID)
    SELECT GROUP_ID, 'ldap:cn=admins,ou=groups,dc=asf,dc=griddynamics,dc=com'
        FROM ACCOUNT_GROUP_NAMES WHERE NAME='Administrators';
INSERT INTO ACCOUNT_GROUP_BY_ID (GROUP_ID, INCLUDE_UUID)
    SELECT GROUP_ID, 'ldap:cn=robots,ou=groups,dc=asf,dc=griddynamics,dc=com'
        FROM ACCOUNT_GROUP_NAMES WHERE NAME='Non-Interactive Users';
_SQL


# Proceed with CMD
#
touch /var/lock/initialized
cd "$gerrit_home"
exec "$@"

