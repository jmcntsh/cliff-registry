#!/usr/bin/env bash
# yazi — blazing-fast terminal file manager
#
# Template 2 (real TUI capture). Yazi's look is the product, so we
# capture the real app instead of approximating it.

# SIZE=100x30

# Build a synthetic home + project tree so the reel never leaks the
# recorder's real machine paths or directory names.
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
demo_root="$tmp_home/demo-repo"

mkdir -p "$demo_root"/{apps,cmd,docs,internal,reels,scripts}
cat > "$demo_root/README.md" <<'EOF'
# demo-repo

Sample project tree used for yazi reel capture.
EOF
cat > "$demo_root/apps/glow.toml" <<'EOF'
name = "glow"
description = "Render markdown on the CLI"
EOF
cat > "$demo_root/apps/yazi.toml" <<'EOF'
name = "yazi"
description = "Blazing-fast terminal file manager"
EOF
touch "$demo_root/go.mod" "$demo_root/go.sum" "$demo_root/CNAME"

# Stop recording automatically after a short first-impression window.
( sleep 7; kill -TERM $$ ) &

# Use a synthetic HOME so yazi's title/path shows "~/<demo>" and not a
# user-specific absolute path. Suppress startup warnings that can occur
# in some recording environments.
export HOME="$tmp_home"
cd "$tmp_home"
exec yazi "demo-repo" 2>/dev/null
