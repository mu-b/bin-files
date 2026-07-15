# bin-files

A version-controlled collection of `~/bin/` scripts and tools for macOS / Linux /
Unix. Scripts live in [`bin/`](bin/) and are deployed to your `~/bin/` directory as
symlinks, so editing a file in the repo immediately updates the installed command.

## Quick start

```sh
git clone <this-repo> bin-files
cd bin-files
./install.sh
```

`install.sh` symlinks everything in `bin/` into `~/bin/` and activates this repo's
git hooks (via `core.hooksPath`). Make sure `~/bin` is on your `PATH`:

```sh
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc   # or ~/.zshrc
```

To install into a different directory:

```sh
BIN_DIR=/usr/local/bin ./install.sh
```

Preview without changing anything:

```sh
./install.sh --dry-run
```

`install.sh` is idempotent — it never clobbers a real (non-symlink) file in the
target directory, and it prunes stale symlinks left behind by removed scripts.

## Adding a new script

1. Drop an executable script into `bin/` (a shebang is expected; the installer
   sets the executable bit for you).
2. Run `./install.sh` — or just `git pull` on another machine, where the
   `post-merge` / `post-checkout` hooks re-run the installer automatically.

> Hooks only take effect **after** the first `./install.sh` on a fresh clone —
> git cannot run repo-tracked hooks until `core.hooksPath` has been set.

## Commit convention

Commits follow [Conventional Commits](https://www.conventionalcommits.org/) and are
enforced by the `commit-msg` hook:

```
<type>[optional scope][!]: <description>
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`,
`ci`, `chore`, `revert`.

```sh
feat: add py-venv activate command
fix(install): skip files that are not symlinks
docs: explain PATH setup
```

## Layout

```
bin-files/
├── .githooks/     # tracked git hooks (activated by install.sh)
├── bin/           # the scripts, symlinked into ~/bin
└── install.sh     # deploy symlinks + activate hooks
```
