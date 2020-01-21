set -e

# Create symlink.
templink="$(mktemp -t "TEMP_symlink_XXXX")"
rm "$templink"
ln -s "$(pwd)/../../src/batgrep.sh" "$templink"
chmod +x "$templink"

# Run symlink.
"$(dirname "$templink")/$(basename "$templink")" "templink" "${BASH_SOURCE[0]}" -C 0 | sed '1d;$d' || true

# Cleanup.
rm "$templink"

