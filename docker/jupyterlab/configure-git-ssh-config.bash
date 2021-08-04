#!/usr/bin/env bash

# helper script for git-config.sh

checkSSHConfig() {
  if [ -f $SSH_CONFIG ]; then
    CONFIG_EXISTS_MESSAGE="An SSH config already exists! "
  fi

  # create new profile
  while ! [[ "$ASK_CREATE_NEW_SSH_CONFIG" =~ ^(y|Y|n|N)$ ]]; do
    echo -n "$CONFIG_EXISTS_MESSAGE""Do you want to create a new GIT+SSH profile? [y/n]: "
    read -r ASK_CREATE_NEW_SSH_CONFIG

    if [ -z "$ASK_CREATE_NEW_SSH_CONFIG" ]; then
      ASK_CREATE_NEW_SSH_CONFIG="N"
    fi

    if [[ "$ASK_CREATE_NEW_SSH_CONFIG" =~ ^(y|Y)$ ]]; then
      configureSSHConfig
    elif [[ "$ASK_CREATE_NEW_SSH_CONFIG" =~ ^(n|N)$ ]]; then
      continue
    fi
  done
}

configureSSHConfig() {
  mkdir -p $SSH_HOME
  cat >$SSH_HOME/config <<EOF
Host github.com
  Hostname ssh.github.com
  Port 443
  AddKeysToAgent yes
  IdentityFile $SSH_HOME/id_rsa
EOF

  while ! [[ -n "$SSH_PASSPHRASE" && -n "$SSH_PASSPHRASE_CONFIRM" ]]; do
    echo -n "Enter passphrase (empty for no passphrase): "
    read -rs SSH_PASSPHRASE
    echo ""
    echo -n "Re-Enter passphrase (empty for no passphrase): "
    read -rs SSH_PASSPHRASE_CONFIRM
    echo ""
    if [[ ! "$SSH_PASSPHRASE" == "$SSH_PASSPHRASE_CONFIRM" ]]; then
      echo "Passphrases do not match.  Try again."
      unset SSH_PASSPHRASE
      unset SSH_PASSPHRASE_CONFIRM
    fi
  done

  ssh-keygen -t rsa -b 4096 -C "$(hostname -s)" -N "$SSH_PASSPHRASE" -f "$SSH_HOME"/id_rsa 2>/dev/null <<<y >/dev/null

  echo "Your public key has been saved in $SSH_HOME/id_rsa.pub"

  chmod 600 "$SSH_HOME"/id_rsa*
  verifySSHPublicKey
}

printSSHPublicKey() {
  cat <<EOF


=====================================================================================================================
===                                        PLEASE PAY ATTENTION                                                   ===
EOF
  if [ -n "$SSH_VERIFICATION_UNSUCCESSFUL" ]; then
    echo "$SSH_VERIFICATION_UNSUCCESSFUL"
  else
    cat <<EOF
=====================================================================================================================
EOF
  fi

  cat <<EOF

An SSH key pair has been generated and the public key must be configured to your GitHub account.

Follow these instructions before you continue:

  1. Logon to: https://github.com
  2. Click on "Account" (located at the top right menu) and choose "Settings"
  3. Click "SSH and GPG keys" from the left menu
  4. Chose "New SSH Key" and give it at name. E.g. "ssb-notebook"

Copy the below snippet and paste to GitHub form field "Key":

EOF

  cat $SSH_HOME/id_rsa.pub

  echo ""

  cat <<EOF
  5. Chose "Add SSH Key"

EOF
}

verifySSHPublicKey() {
#  SSH_AGENT_PID=$(pgrep -x "ssh-agent")
#  if [ -n "$SSH_AGENT_PID" ]; then
#    echo "Stopping ssh-agent PID: $SSH_AGENT_PID"
#    kill -9 "$SSH_AGENT_PID"
#  fi
  printSSHPublicKey

  while [[ -z "$ASK_VERIFY_SSH_KEY" ]]; do
    echo -n "Please confirm that your SSH key is registered at GitHub [y/n/cancel]: "
    read -r CONFIRM_SSH_CHECK

    if [[ "$CONFIRM_SSH_CHECK" =~ ^(y|Y)$ ]]; then
      SSH_RESULT=$(ssh -T -i $SSH_HOME/id_rsa -p 443 git@ssh.github.com 2>&1)

      if [[ "$SSH_RESULT" == *"successfully authenticated"* ]]; then
        ASK_VERIFY_SSH_KEY=true
        SSH_CONFIG_SUCCESSFUL=true

        # Remove git credential helper when using SSH agent
        RECONFIGURE_GIT_CONFIG=$(sed '/helper = cache/d' "$GIT_CONFIG")
        echo "$RECONFIGURE_GIT_CONFIG" >"$GIT_CONFIG"

        # Copy ssh-agent script to .local/profile.d/
        cp "$HOME/.local/profile.skel/01-ssh-agent.sh" "$HOME/.local/profile.d/01-ssh-agent.sh"

        cat <<EOF

Your ssh-config is successfully configured!

EOF
#        if [[ -z $(pgrep -x "ssh-agent") ]]; then
#          echo "Starting ssh-agent"
#          eval $(ssh-agent -s)
#        fi
      else
        SSH_VERIFICATION_UNSUCCESSFUL=$(
          cat <<END
===                                                                                                               ===
===  Unsuccessful verification of SSH PublicKey at GibHub. Please verify your GitHub SSH key configuration.  ===
===                                                                                                               ===
=====================================================================================================================
END
        )
        printSSHPublicKey
      fi
    elif [[ "$CONFIRM_SSH_CHECK" =~ ^(n|N)$ ]]; then
      printSSHPublicKey
      unset ASK_VERIFY_SSH_KEY
    elif [[ "$CONFIRM_SSH_CHECK" =~ ^(cancel|Cancel|CANCEL)$ ]]; then
      ASK_VERIFY_SSH_KEY=true
    fi
  done
}

createSSHConfig() {
  checkSSHConfig
}
