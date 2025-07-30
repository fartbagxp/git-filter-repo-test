#!/usr/bin/env bash

set -e

usage() {
  echo "Usage: $0 <file-path>"
  echo ""
  echo "This script finds git blob IDs for all previous versions of a file,"
  echo "excluding the latest version, so you can delete the file's history"
  echo "while keeping the current version."
  echo ""
  echo "Arguments:"
  echo "  file-path    Path to the file (relative to git repository root)"
  echo ""
  echo "Example:"
  echo "  $0 data/large-file.bin"
  echo "  $0 secrets/config.env"
  exit 1
}

if [ $# -ne 1 ]; then
  echo "Error: File path argument is required."
  echo ""
  usage
fi

FILE_PATH="$1"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: Not in a git repository."
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "Warning: File '$FILE_PATH' does not exist in the current working tree."
  echo "This script will still search for historical versions of this file."
  echo ""
fi

echo "=== Git Blob History Cleaner ==="
echo "File: $FILE_PATH"
echo "Repository: $(git rev-parse --show-toplevel)"
echo ""

TEMP_BLOBS=$(mktemp)
trap 'rm -f "$TEMP_BLOBS"' EXIT

echo "Searching for blob IDs of previous versions..."

declare -a all_blobs=()
declare -a all_versions=()
declare -A seen_paths=()

while read -r blob path; do
  if [[ -z "$blob" || -z "$path" ]]; then
    continue
  fi
  
  if [[ "$path" == "$FILE_PATH" ]]; then
    all_blobs+=("$blob")
    if [[ -n "${seen_paths[$path]}" ]]; then
      all_versions+=("$blob PREVIOUS")
    else
      all_versions+=("$blob LATEST")
    fi
    seen_paths["$path"]=1
  fi
done < <(git rev-list --objects HEAD | grep -E "^[a-f0-9]+ " || true)

exec 3>&1
exec 1>&2

echo "=== Debug Information ==="
echo "File: $FILE_PATH"
echo "Total versions found: ${#all_blobs[@]}"

if [[ ${#all_blobs[@]} -gt 0 ]]; then
  delete_count=$((${#all_blobs[@]} - 1))
  echo "Versions to delete: $delete_count"
  echo ""
  
  echo "Version details:"
  for i in "${!all_versions[@]}"; do
    version_info="${all_versions[i]}"
    blob_id="${version_info%% *}"
    status="${version_info##* }"
    version_num=$((i + 1))
    echo "  $version_num. ${blob_id:0:12}... ($status)"
  done
  
  if [[ $delete_count -gt 0 ]]; then
    echo ""
    echo "Blob IDs to delete:"
    for ((i=1; i<${#all_blobs[@]}; i++)); do
      echo "  ${all_blobs[i]}"
    done
  else
    echo ""
    echo "No previous versions found - nothing to delete."
  fi
else
  echo "No versions of $FILE_PATH found in git history."
fi

exec 1>&3
exec 3>&-

if [[ ${#all_blobs[@]} -le 1 ]]; then
  echo "" > "$TEMP_BLOBS"
else
  for ((i=1; i<${#all_blobs[@]}; i++)); do
    echo "${all_blobs[i]}"
  done > "$TEMP_BLOBS"
fi

if [ ! -s "$TEMP_BLOBS" ]; then
  echo "No previous versions of '$FILE_PATH' found in git history."
  echo "The file either:"
  echo "  - Has only one version (current)"
  echo "  - Does not exist in git history"
  echo "  - Has no commits affecting this file"
  exit 0
fi

echo ""
echo "=== Results ==="
BLOB_COUNT=$(wc -l < "$TEMP_BLOBS")
echo "Found $BLOB_COUNT blob(s) to delete for '$FILE_PATH'"
echo ""

echo "To delete these blobs and wipe the file's history:"
echo ""
echo "1. Save the blob IDs to a file:"
echo "   $0 '$FILE_PATH' > blobs-to-delete.txt"
echo ""
echo "2. Use git-filter-repo to remove them:"
echo "   git filter-repo --force --strip-blobs-with-ids blobs-to-delete.txt"
echo ""
echo "3. Clean up:"
echo "   rm blobs-to-delete.txt"
echo ""

echo "WARNING: This operation will rewrite git history!"
echo "Make sure you have a backup of your repository before proceeding."
echo ""

cat "$TEMP_BLOBS"
