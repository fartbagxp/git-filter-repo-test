#!/usr/bin/env bash

# Usage:
#   bash find-objects-exceed-size.sh [SIZE_IN_MB]
#
# Arguments:
#   SIZE_IN_MB - Size threshold in megabytes (optional, default: 100)
#
# Output:
#   large-files-removed.log      - List of files exceeding threshold with sizes
#   large-files-with-dates.log   - Same list with last commit timestamps
#
# Examples:
#   bash find-objects-exceed-size.sh      # Checks for files >= 100MB (default)
#   bash find-objects-exceed-size.sh 10   # Checks for files >= 10MB
#   bash find-objects-exceed-size.sh 1    # Checks for files >= 1MB
#   bash find-objects-exceed-size.sh 0.1  # Checks for files >= 0.1MB (100KB)

set -e

# Default size threshold in MB
SIZE_MB=${1:-100}

# Convert MB to bytes (1 MB = 1024 * 1024 bytes = 1048576 bytes)
# Using awk to support decimal values (e.g., 0.1 for 100KB)
SIZE_BYTES=$(awk "BEGIN {printf \"%.0f\", $SIZE_MB * 1048576}")

if command -v git > /dev/null 2>&1 ; then
  echo "git is installed"
else
  echo "git is not installed! Please install git and run again!"
  exit
fi

find_large_files() {
  local threshold=$1
  local output_file="large-files-to-remove.log"
  
  printf "Searching for files >= %s MB (>= %s bytes)...\n" "$SIZE_MB" "$threshold"
  
  git rev-list --objects --all | \
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
    awk -v threshold="$threshold" '$1 == "blob" && $3 >= threshold {
      size_mb = $3 / 1048576
      file = $4
      for(i=5; i<=NF; i++) file = file " " $i
      print size_mb " MB\t" file
    }' | \
    sort -rn > "$output_file"
  
  local count
  count=$(wc -l < "$output_file")
  printf "Found %s file(s) exceeding threshold\n" "$count"
  printf "Results saved to: %s\n" "$output_file"
}

add_timestamps() {
  local input_file="large-files-to-remove.log"
  local output_file="large-files-with-dates.log"
  
  if [ ! -s "$input_file" ]; then
    printf "No files to process for timestamps\n"
    return
  fi
  
  printf "Adding last commit timestamps...\n"
  
  while IFS=$'\t' read -r size file; do
    last_commit=$(git log --all --pretty=format:"%ci" -- "$file" | head -1)
    printf "%s\t%s\t%s\n" "$size" "$file" "$last_commit"
  done < "$input_file" > "$output_file"

  mv "$output_file" "$input_file"
  printf "Timestamps added to: %s\n" "$output_file"
}

main() {
  printf "=== Git Large File Finder ===\n"
  printf "Threshold: %s MB\n\n" "$SIZE_MB"
  
  find_large_files "$SIZE_BYTES"
  echo
  add_timestamps
  
  printf "\n=== Complete ===\n"
}

main