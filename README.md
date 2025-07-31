# Repository History Rewrite

To properly rewrite Git history, we rely on a tool called [git-filter-repo](https://github.com/newren/git-filter-repo) based on [Github's recommendation on removing sensitive material from Github](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository#purging-a-file-from-your-local-repositorys-history-using-git-filter-repo).

Use cases on how to use this:

- [Remove a file](./docs/examples.md#removing-a-file) wipes a single file from Git history.
- [Keeping last commit of file](./docs/examples.md#keep-last-commit-of-file) wipes previous history before last of any particular file.

## Helpful Introduction

- [Elijah Newren's talk on git-repo-filter](https://www.youtube.com/watch?v=KXPmiKfNlZE) is an excellent introduction to learning how to use git-repo-filter.
- [Various Use Cases of git-repo-filter](https://github.com/newren/git-filter-repo/blob/main/README.md#how-do-i-use-it)
