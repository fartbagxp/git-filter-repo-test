# Repository History Rewrite

To properly rewrite Git history, we rely on a tool called [git-filter-repo](https://github.com/newren/git-filter-repo) based on [Github's recommendation on removing sensitive material from Github](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository#purging-a-file-from-your-local-repositorys-history-using-git-filter-repo).

Follow [examples](https://github.com/newren/git-filter-repo/blob/main/README.md#how-do-i-use-it) to learn how to use it.

## Rewriting a File

- Capture the remote as the next script will wipe it out.

```bash
git remote -v
```

- Run git-filter-repo on the file - data/test/test3.json.

```bash
git-filter-repo --invert-paths --path data/test/test3.json
```

- Verify what has been removed

```bash
grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs

```

- Add the remote origin back:

```bash
git remote add git@github.com-fartbagxp:fartbagxp/git-filter-repo-test.git
```

- Once we feel satisified with the changes, run the forced push.

```bash
git push --force --mirror origin
```

## Helpful Introduction

- [Elijah Newren's talk on git-repo-filter](https://www.youtube.com/watch?v=KXPmiKfNlZE) is an excellent introduction to learning how to use git-repo-filter.
