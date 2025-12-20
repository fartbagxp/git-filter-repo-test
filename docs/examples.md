# Examples

These are use cases on how to use [git-filter-repo](https://github.com/newren/git-filter-repo) to rewrite git history.

- [Removing Sensitive Info (eg. passwords)](#removing-sensitive-info)
- [Removing a File](#removing-a-file)
- [Removing Files Larger than 100MB](#removing-files-larger-than-100mb)
- [Keep Last Commit of File](#keep-last-commit-of-file)

## Removing Sensitive Info

This workflow removes sensitive information (passwords, API keys, tokens) from Git history based on [Github's guide to removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository#about-sensitive-data-exposure). Prior to removing the sensitive info as it is already exposed, restrict access from it from being used.

1. Do a fresh checkout/clone of the repository. git-filter-repo will warn when running on a repository without a fresh checkout/clone: `git clone --mirror <path>`.

1. Take note on pull requests, path changes, and files where the sensitive info appears.

1. Create a plain text file (eg. passwords.txt) containing the sensitive data patterns to remove (one per line). Based on [v2.47.0](https://github.com/newren/git-filter-repo/blob/v2.47.0/git-filter-repo#L2015-L2021), each line is treated literal, but regex may be used. If special characters such as `$` is part of the replacement, it has to be escaped via `\$`.

   ```bash
   echo "my-secret-password" > passwords.txt
   echo "api-key-12345" >> passwords.txt
   ```

1. Run git-filter-repo to remove the sensitive data from history.

   ```bash
   git-filter-repo --sensitive-data-removal --replace-text passwords.txt
   ```

1. Once we feel satisfied with the changes, run the forced push.

   ```bash
   git push --force --mirror origin
   ```

1. The push may fail for some git refs from Github.com but should otherwise replace the proper text. Verify by looking at the content and the pull requests associated that the sensitive content has been replaced with "\*\*\*REMOVED\*\*\*".

## Removing a File

This workflow removes a file from Git history.

1. Do a fresh checkout/clone of the repository. git-filter-repo will warn when running on a repository without a fresh checkout/clone.

1. Capture the remote as the next script will wipe it out.

   ```bash
   git remote -v
   ```

1. Run git-filter-repo on the file - data/test/test3.json. You can run this command numerous times to remove selective files.

   ```bash
   git-filter-repo --invert-paths --path data/test/test3.json
   ```

1. Restore the remote origin on the local checkout. This is because git-filter-repo creates history [incompatible with the original git history](https://github.com/newren/git-filter-repo/issues/46#issuecomment-573733491).

   ```bash
   git remote add origin git@github.com-fartbagxp:fartbagxp/git-filter-repo-test.git
   ```

1. (Optional) Verify what has been removed through pull requests.

   ```bash
   grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs
   ```

> [!IMPORTANT]
> If all git pushes were made directly to the trunk branch instead of pull requests, the result will be 0.

1. Once we feel satisified with the changes, run the forced push.

   ```bash
   git push --force --mirror origin
   ```

## Removing Files Larger than 100MB

This workflow covers a technique to filter out files larger than 100MB, which is GitHub's file size limit when migrating from another environment (e.g Azure Devops, Gitlab, Bitbucket).

Prerequisites:

- [git-filter-repo](https://github.com/newren/git-filter-repo) installed
- Access to both source and destination repositories
- Sufficient disk space for the repository clone

---

1. Create a mirror clone of the source repository

   ```bash
   git clone --mirror "source-repository-url"
   cd "repository-name"
   ```

1. Analyze and identify large files.

   ```bash
   git-filter-repo --analyze --force
   ```

   This creates an analysis in `.git/filter-repo/analysis/`. Review the `blob-shas-and-paths.txt` file to see all blobs with their sizes.

   Alternately, run `bash find-objects-exceed-size.sh 100` to search for files exceeding 100MB. This creates `large-files-to-remove.log` containing the size, filename, and last commit date of each large file.

1. Keep track of the repository size. This is used for verification later.

   ```bash
   bash verify-repo-size.sh
   ```

1. Remove files larger than 100MB from history

   ```bash
   git-filter-repo --strip-blobs-bigger-than 100M --force
   ```

   This command removes all files larger than 100MB from the entire Git history.

1. Set up the new remote repository

   If migrating to a new GitHub repository:

   ```bash
   git remote add origin "new-github-repository-url"
   ```

1. Push to the new repository

   ```bash
   git push --mirror origin
   ```

1. Verify that if files were deleted, that the repository is smaller in size.

   ```bash
   bash verify-repo-size.sh
   ```

1. Review the log file `large-files-with-dates.log` to confirm what was removed.

> [!WARNING]
>
> - This process rewrites Git history and changes all commit SHAs
> - All contributors must re-clone the repository after migration
> - Open pull requests will need to be recreated
> - Keep the `large-files-with-dates.log` file for reference of removed files

> [!TIP]
> If you need to preserve large files, consider:
>
> - Storing them in [Git LFS (Large File Storage)](https://git-lfs.github.com/)
> - Moving them to a separate storage system (S3, Azure Blob Storage, etc.)
> - Using GitHub Releases for binary assets

## Keep Last Commit of File

This workflow keeps the current version of a file while wiping its entire git history. Common use cases include removing sensitive data (credentials, API keys) or cleaning up binary files (.png, .jpg, .exe, .dll) that significantly increase repository size when their history is preserved.

1. Capture the remote as the next script will wipe it out.

   ```bash
   git remote -v
   ```

1. Do a fresh checkout/clone of the repository. git-filter-repo will warn when running on a repository without a fresh checkout/clone.

1. Run [find-blobs-to-delete](../find-blobs-to-delete.sh) on a file to generate a list of blob ids based on the git commit history of the file.

   ```bash
   bash find-blobs-to-delete.sh data/test.json > blobs-to-delete.txt
   ```

1. Use git-filter-repo to wipe history based on blob ids.

   ```bash
   git filter-repo --force --strip-blobs-with-ids blobs-to-delete.txt
   ```

1. Restore the remote origin on the local checkout. This is because git-filter-repo creates history [incompatible with the original git history](https://github.com/newren/git-filter-repo/issues/46#issuecomment-573733491).

   ```bash
   git remote add origin git@github.com-fartbagxp:fartbagxp/git-filter-repo-test.git
   ```

1. (Optional) Verify what has been removed through pull requests.

   ```bash
   grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs
   ```

> [!IMPORTANT]
> If all git pushes were made directly to the trunk branch instead of pull requests, the result will be 0.

1. Once we feel satisified with the changes, run the forced push.

   ```bash
   git push --force --mirror origin
   ```

1. Verify that the file is retained, but previous history of the file has been wiped.
