set -e

# Create symlink.
templink="$(basename "$0" ".sh")._temp"
tempabs="$(pwd)/${templink}"
ln -s "../../src/batgrep.sh" "$templink"
chmod +x "$templink"

# Run symlink.
export PATH="$(pwd):$PATH"
cd /tmp
"$(basename "$templink")" "templink" "${BASH_SOURCE[0]}" -C 0 | sed '1d;$d' || true

# Cleanup.
rm "$tempabs"

