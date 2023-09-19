#!/bin/sh

echo "Replacing environment variables"

perl -pe 's/\$([_A-Z]+)/$ENV{$1}/g' </tmp/spark-defaults.conf >> /usr/local/spark/conf/spark-defaults.conf

# Copy .bashrc and .profile if it doesn't already exist on mounted home volume
if [ ! -f "$HOME/.bashrc" ]; then
  cp /etc/skel/.bashrc "$HOME/.bashrc"
  printf "\ncheck-git-config.sh" >>"$HOME/.bashrc"
  chown jovyan "$HOME/.bashrc"
fi

if [ ! -f "$HOME/.profile" ]; then
  cp /etc/skel/.profile "$HOME/.profile"
  chown jovyan "$HOME/.profile"
fi

# enable local profile.d scripts
LOCAL_PROFILE=$(cat $HOME/.profile)
MATCH_TOKEN="source local profile.d scripts"
case "$LOCAL_PROFILE" in
*$MATCH_TOKEN*)
  # do nothing
  ;;
*)
  cat >>$HOME/.profile <<EOF

# source local profile.d scripts
if [ -d \$HOME/.local/profile.d ]; then
  for i in \$HOME/.local/profile.d/*.sh; do
    if [ -r \$i ]; then
      . \$i
    fi
  done
  unset i
fi
EOF

  mkdir -p "$HOME/.local/profile.d"
  chown -R jovyan "$HOME/.local/profile.d"
  ;;
esac
unset LOCAL_PROFILE
unset MATCH_TOKEN

# Copy ssh-agent init skel script
mkdir -p "$HOME/.local/profile.skel"
cat >$HOME/.local/profile.skel/01-ssh-agent.sh <<EOF
# reset ssh keys permissions
if [ -f \$HOME/.ssh/id_rsa ]; then
  chmod 600 \$HOME/.ssh/id_rsa*
fi

. /usr/local/bin/ssh-agent-helper.sh

start_ssh_agent
init_ssh_agent_env
EOF
chown -R jovyan "$HOME/.local/profile.skel"

if [ -e /home/jovyan/.cache//git/credential ]
then
    chmod --silent 0700 /home/jovyan/.cache//git/credential
fi
