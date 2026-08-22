#!/usr/bin/env bash
# Install the pre-commit linkage gate. OPT-IN, PER CLONE, AND NOT THE CHECK.
#
# .git/hooks is not versioned, so this does not propagate: every clone that
# wants the gate installs it. That is a real limitation and not worth hiding --
# see CONVENTIONS.md, "Committing in a tree another agent is working in".
#
# THE HOOK WOULD HAVE MISSED THE ONLY INSTANCE WE HAVE. d6d3423 was made with
# `git commit-tree` + `git update-ref`, which runs no hooks, and that is the
# procedure the convention recommends for a shared index. `--no-verify` also
# bypasses it. The authoritative check is:
#     scripts/check_linkage_tree.sh --audit origin/main..HEAD
# run by whoever pushes.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="$REPO/.git/hooks/pre-commit"
if [ -e "$H" ] && ! grep -q check_linkage_tree "$H" 2>/dev/null; then
  echo "refusing: $H exists and is not ours. Merge by hand." >&2; exit 1
fi
cat > "$H" <<'HOOK'
#!/usr/bin/env bash
# Installed by scripts/install_hooks.sh. A convenience gate, not the check.
exec "$(git rev-parse --show-toplevel)/scripts/check_linkage_tree.sh" --staged
HOOK
chmod +x "$H"
echo "installed $H"
echo "NOTE: this gate does not cover commit-tree/update-ref, --no-verify, or any"
echo "      other clone. Before pushing, run:"
echo "      scripts/check_linkage_tree.sh --audit origin/main..HEAD"
