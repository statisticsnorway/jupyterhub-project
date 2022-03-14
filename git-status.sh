#!/usr/bin/env bash

printf '\jupyterhub-project'
echo "----------------------------------------------------------------"
git status --short

while read -r repo
do
  printf '\n%s' "${repo}"
  echo "----------------------------------------------------------------"
  git -C ${repo} status --short
done < git-repos.txt
