# Protect against anything which thinks its being clever by appending to
# profile files that `sudo -s`, rcp, and scp might source.
if [[ "$EUID" -eq 0 ]]; then
        return
fi
