#!/usr/bin/env bash

export GIT_CONFIG=/tmp/gitconfig
export SSH_HOME=/tmp/ssh
export SSH_CONFIG=/tmp/ssh/config

#. "$(dirname $BASH_SOURCE)/configure-git-config.bash"
. "$(dirname $BASH_SOURCE)/configure-git-ssh-config.bash"

cat <<EOF

---------------------------------------------------------------------------------------------------------------------
|    ________.__  __      _________       __                                                                        |
|    /  _____/|__|/  |_   /   _____/ _____/  |_ __ ________                                                         |
|   /   \  ___|  \   __\  \_____  \_/ __ \   __\  |  \____ \\                                                        |
|   \    \_\  \  ||  |    /        \  ___/|  | |  |  /  |_> >                                                       |
|    \______  /__||__|   /_______  /\___  >__| |____/|   __/                                                        |
|            \/                   \/     \/           |__|                                                          |
|                                                                                                                   |
| This script will take you through the process of configuring Git, Git+SSH and setup of your GitHub account.       |
|                                                                                                                   |
| Please pay attention as you go.                                                                                   |
|                                                                                                                   |
---------------------------------------------------------------------------------------------------------------------

EOF

#createGitConfig
createSSHConfig

if [[ "$GIT_CONFIG_SUCCESSFUL" == true || "$SSH_CONFIG_SUCCESSFUL" == true ]]; then
  cat <<EOF

For further reading regarding use, please refer to the documentation at:
https://github.com/statisticsnorway/dapla-project/blob/master/doc/jupyter-git.adoc

EOF
fi
