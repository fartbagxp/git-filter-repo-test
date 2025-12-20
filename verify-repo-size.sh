#!/usr/bin/env bash
#
# Verify the size of the Git repository
#
# Usage:
#   bash verify-repo-size.sh

set -eu

echo "Verifying Git repository size..."

if command -v git > /dev/null 2>&1 ; then
  echo "git is installed"
else
  echo "git is not installed! Please install git and run again!"
  exit
fi

git count-objects -vH