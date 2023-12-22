#!/usr/bin/env bash
NETRC_FILE="$HOME/.netrc"
INIT_PATH="$HOME"/work

if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_PERSONAL_ACCESS_TOKEN" ]; then
  if [ ! -f "$NETRC_FILE" ]; then
    echo "machine github.com login $GIT_USER_NAME password $GIT_PERSONAL_ACCESS_TOKEN" >>"$NETRC_FILE"
  fi
fi

# Configure git
if [ -n "$GIT_USER_NAME" ]; then
  git config --global user.name "$GIT_USER_NAME"
fi

if [ -n "$GIT_USER_MAIL" ]; then
  git config --global user.email "$GIT_USER_MAIL"
fi

if [ -n "$GIT_REPOSITORY" ] && [ -f "$NETRC_FILE" ]; then
  REPO_NAME="$(basename "$GIT_REPOSITORY" .git)"
  REPO_PATH="$INIT_PATH/$REPO_NAME"
  git clone "$GIT_REPOSITORY" "$REPO_PATH"

  if [ -d "$REPO_PATH" ]; then
    INIT_PATH="$REPO_PATH"
    if [ -n "$GIT_BRANCH" ]; then
      cd "$REPO_PATH"
      git checkout "$GIT_BRANCH"
      cd -
    fi
  fi
fi

echo "execution of $*"
exec "$@" "$INIT_PATH"