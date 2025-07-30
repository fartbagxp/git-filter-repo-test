# Repository History Rewrite

To properly rewrite Git history, we rely on a tool called [git-filter-repo](https://github.com/newren/git-filter-repo) based on [Github's recommendation on removing sensitive material from Github](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository#purging-a-file-from-your-local-repositorys-history-using-git-filter-repo).

Follow [examples](https://github.com/newren/git-filter-repo/blob/main/README.md#how-do-i-use-it) to learn how to use it.

## Rewriting a File

1. Do a fresh checkout/clone of the repository. git-filter-repo will warn when running on a repository without a fresh checkout/clone.

1. Capture the remote as the next script will wipe it out.

   ```bash
   git remote -v
   ```

1. Run git-filter-repo on the file - data/test/test3.json.

   ```bash
   git-filter-repo --invert-paths --path data/test/test3.json
   ```

1. Verify what has been removed.

   ```bash
   grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs
   ```

1. Add the remote origin back. This is because git-filter-repo creates history [incompatible with the original git history](https://github.com/newren/git-filter-repo/issues/46#issuecomment-573733491).

   ```bash
   git remote add git@github.com-fartbagxp:fartbagxp/git-filter-repo-test.git
   ```

1. Once we feel satisified with the changes, run the forced push.

   ```bash
   git push --force --mirror origin
   ```

## Keep Last Commit of File

This strategy keeps the current version of a file while wiping its entire git history. Common use cases include removing sensitive data (credentials, API keys) or cleaning up binary files (.png, .jpg, .exe, .dll) that significantly increase repository size when their history is preserved.

1. Capture the remote as the next script will wipe it out.

   ```bash
   git remote -v
   ```

1. Do a fresh checkout/clone of the repository. git-filter-repo will warn when running on a repository without a fresh checkout/clone.

1. Run [find-blobs-to-delete](./find-blobs-to-delete.sh) on a file to generate a list of blob ids based on the git commit history of the file.

   ```bash
   bash find-blobs-to-delete.sh data/test.json > blobs-to-delete.txt
   ```

1. Use git-filter-repo to wipe history based on blob ids.

   ```bash
   git filter-repo --force --strip-blobs-with-ids blobs-to-delete.txt
   ```

1. Add the remote origin back. This is because git-filter-repo creates history [incompatible with the original git history](https://github.com/newren/git-filter-repo/issues/46#issuecomment-573733491).

   ```bash
   git remote add git@github.com-fartbagxp:fartbagxp/git-filter-repo-test.git
   ```

1. Once we feel satisified with the changes, run the forced push.

   ```bash
   git push --force --mirror origin
   ```

1. Verify that the file is retained, but previous history of the file has been wiped.

## Helpful Introduction

- [Elijah Newren's talk on git-repo-filter](https://www.youtube.com/watch?v=KXPmiKfNlZE) is an excellent introduction to learning how to use git-repo-filter.
