#!/usr/bin/env sh

SSH_AUTH_SOCK_FILE=$HOME/.ssh/ssh_auth_sock

start_ssh_agent() {
  if [ ! -S "$SSH_AUTH_SOCK_FILE" ]; then
    eval $(ssh-agent -s)
    ln -sf "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK_FILE"
  fi
}

stop_ssh_agent() {
  SSH_AGENT_PIDS=$(pgrep -d' ' -f "ssh-agent")
  if [ -n "$SSH_AGENT_PIDS" ]; then
    trap $(kill -9 "$SSH_AGENT_PIDS") 0
    rm "$SSH_AUTH_SOCK_FILE"
  fi
}

init_ssh_agent_env() {
  export SSH_AUTH_SOCK=$SSH_AUTH_SOCK_FILE
  ssh-add -l > /dev/null || ssh-add
}
