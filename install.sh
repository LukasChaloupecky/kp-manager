#!/usr/bin/env bash
#
# kp-manager installer (user level: no root, no sudo)
#
#   curl -fsSL https://raw.githubusercontent.com/LukasChaloupecky/kp-manager/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/LukasChaloupecky/kp-manager/main/install.sh | bash -s -- --uninstall
#
# Installs into your home directory:
#   ~/.local/bin/kp-manager
#   ~/.local/share/man/man1/kp-manager.1

set -euo pipefail

REPO=${KP_REPO:-LukasChaloupecky/kp-manager}
REF=${KP_REF:-main}                        # branch, tag or commit
ACTION=install

say()  { printf '%s\n' "$*"; }
fail() { printf 'install: %s\n' "$*" >&2; exit 1; }

while (( $# )); do
  case $1 in
    --ref)        [[ $# -ge 2 ]] || fail "--ref needs a value"; REF=$2; shift ;;
    --uninstall)  ACTION=uninstall ;;
    -h|--help)
      cat <<EOF
kp-manager installer (installs for the current user in ~/.local, no root needed)

Usage: install.sh [--ref BRANCH|TAG] [--uninstall]
  --ref REF     branch, tag or commit to install (default: main)
  --uninstall   remove kp-manager and its man page
Your settings and logs (~/.config/kp-manager, ~/.local/state/kp-manager) are never touched.
EOF
      exit 0 ;;
    *)            fail "unknown option: $1 (try --help)" ;;
  esac
  shift
done

[[ -n ${HOME:-} ]] || fail "HOME is not set"
(( EUID != 0 )) || say "Note: running as root, so this installs into root's home ($HOME), not your own."

BASE_URL=${KP_BASE_URL:-https://raw.githubusercontent.com/$REPO/$REF}
BIN_DIR=$HOME/.local/bin
MAN_DIR=$HOME/.local/share/man/man1

if [[ $ACTION == uninstall ]]; then
  rm -f -- "$BIN_DIR/kp-manager" "$MAN_DIR/kp-manager.1"
  say "Removed kp-manager from ~/.local"
  exit 0
fi

fetch() {   # URL DEST
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 -o "$2" "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    fail "curl or wget is required"
  fi
}

TMP=$(mktemp -d "${TMPDIR:-/tmp}/kp-manager-install.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT

say "Downloading kp-manager ($REF)..."
fetch "$BASE_URL/kp-manager"   "$TMP/kp-manager"   || fail "could not download $BASE_URL/kp-manager"
fetch "$BASE_URL/kp-manager.1" "$TMP/kp-manager.1" || fail "could not download $BASE_URL/kp-manager.1"

# check before installing anything
head -n 1 "$TMP/kp-manager" | grep -q '^#!.*bash' || fail "downloaded file is not the kp-manager script (wrong repo or ref?)"
bash -n "$TMP/kp-manager" || fail "downloaded script has a syntax error; nothing was installed"
grep -q '^\.TH KP-MANAGER' "$TMP/kp-manager.1" || fail "downloaded man page looks wrong; nothing was installed"

install -d -m755 "$BIN_DIR" "$MAN_DIR"
install -m755 "$TMP/kp-manager"   "$BIN_DIR/kp-manager"
install -m644 "$TMP/kp-manager.1" "$MAN_DIR/kp-manager.1"

say "Installed:"
say "  $BIN_DIR/kp-manager"
say "  $MAN_DIR/kp-manager.1"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) say ""
     say "Note: $BIN_DIR is not in your PATH. Add this line to ~/.bashrc, then open a new terminal:"
     say "  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

missing=()
for t in flock sha256sum; do command -v "$t" >/dev/null 2>&1 || missing+=("$t"); done
if (( ${#missing[@]} )); then
  say ""
  say "Missing required program(s): ${missing[*]} (packages: util-linux, coreutils)"
fi
say ""
say "Next: run  kp-manager init   (and  man kp-manager  for the manual)"
