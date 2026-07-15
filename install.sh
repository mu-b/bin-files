#!/usr/bin/env bash
#
# install.sh - deploy the scripts in ./bin into the user's ~/bin as symlinks
#              and activate this repo's tracked git hooks.
#
#   ./install.sh              install/refresh symlinks + activate hooks
#   ./install.sh --dry-run    show what would happen, change nothing
#   ./install.sh --help       show this help
#
# The target directory defaults to ~/bin and can be overridden:
#   BIN_DIR=/somewhere/else ./install.sh
#
# Safe to run repeatedly: it is idempotent, never clobbers non-symlink files,
# and prunes stale symlinks that used to point into this repo's bin/.

set -euo pipefail

DRY_RUN=0

usage() {
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

# resolve the real path of this script, following symlinks, to find the repo root
_resolve_self() {
    local src="${BASH_SOURCE[0]}" dir
    while [[ -h "$src" ]]; do
        dir="$(cd -P "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        [[ "$src" != /* ]] && src="$dir/$src"
    done
    cd -P "$(dirname "$src")" && pwd
}

# echo the action; run it unless in dry-run mode
run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf 'would: %s\n' "$*"
    else
        "$@"
    fi
}

main() {
    case "${1:-}" in
        -h|--help) usage; return 0 ;;
        -n|--dry-run) DRY_RUN=1 ;;
        "") ;;
        *) echo "install.sh: unknown option '$1'" >&2; usage >&2; return 2 ;;
    esac

    local repo_root src_dir target
    repo_root="$(_resolve_self)"
    src_dir="$repo_root/bin"
    target="${BIN_DIR:-$HOME/bin}"

    if [[ ! -d "$src_dir" ]]; then
        echo "install.sh: no bin/ directory at $src_dir" >&2
        return 1
    fi

    run mkdir -p "$target"

    local linked=0 skipped=0 ok=0 pruned=0
    local f name dest cur

    # link every regular file in bin/ into the target directory
    for f in "$src_dir"/*; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        dest="$target/$name"

        [[ -x "$f" ]] || run chmod +x "$f"

        if [[ -L "$dest" ]]; then
            cur="$(readlink "$dest")"
            if [[ "$cur" == "$f" ]]; then
                ok=$((ok + 1))
                continue
            fi
            run ln -sfn "$f" "$dest"
            linked=$((linked + 1))
        elif [[ -e "$dest" ]]; then
            echo "skip:  $dest exists and is not a symlink (leaving untouched)" >&2
            skipped=$((skipped + 1))
        else
            run ln -s "$f" "$dest"
            linked=$((linked + 1))
        fi
    done

    # prune stale symlinks that point into our bin/ but whose source is gone
    for dest in "$target"/*; do
        [[ -L "$dest" ]] || continue
        cur="$(readlink "$dest")"
        if [[ "$cur" == "$src_dir/"* && ! -e "$cur" ]]; then
            run rm -f "$dest"
            pruned=$((pruned + 1))
        fi
    done

    # activate the tracked git hooks when run inside the work-tree
    if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        run git -C "$repo_root" config core.hooksPath .githooks
    fi

    printf 'install.sh: target=%s  linked=%d ok=%d skipped=%d pruned=%d\n' \
        "$target" "$linked" "$ok" "$skipped" "$pruned"

    case ":$PATH:" in
        *":$target:"*) ;;
        *) echo "note: $target is not in your PATH; add it to your shell rc" >&2 ;;
    esac
}

main "$@"
