#!/bin/bash
#
# Known Bugs:
# - Newlines in filenames will confuse --all-* modes and the default mode does
#   not support NULL-delimited output so they should not be used as input
#   sources for further scripting.
#   (I figured the chances of newlines in filenames in this particular case was
#   too low to justify the extra work)
#
# Sources:
# - http://unix.stackexchange.com/a/38691 (Broken symlink detection)
# - http://unix.stackexchange.com/a/12921 (Printing a subset of `ls -l` output)
# - http://manpages.ubuntu.com/manpages/maverick/en/man1/readlink.1.html (Resolving multiply-layered symlinks)
# - http://stackoverflow.com/a/18086548   (Output capture)
# - https://superuser.com/questions/507267/how-to-grep-for-special-character-nul

filtered_symfind() {
    find "$PWD" -type l -printf '%-80P ->\0' -exec readlink -m {} \; | grep -aP$1 "\x00$2" | sed 's@\x0@ @'
}

case "$1" in
    --help)
        echo "Modes of operation:"
        echo " --all-external"
        echo "  Show all symlinks targeted outside the current directory"
        echo " --all-home"
        echo "  Show all symlinks targeted inside /home"
        echo " --all-my-home"
        echo "  Show all symlinks targeted inside the current user's home directory"
        echo " (anything else)"
        echo "  Show all broken symlinks originating inside the current directory"
        ;;
    --all-external)
        filtered_symfind "v" "$(pwd)" ;;
    --all-home)
        filtered_symfind "" "/home" ;;
    --all-my-home)
        filtered_symfind "" "$HOME" ;;
    *)
        unset t_std t_err
        # shellcheck disable=SC2030
        eval "$( (
            find "$PWD" -type l -xtype l -printf "%-70P -> " -exec readlink -m {} \;
        ) 2> >(t_err=$(cat); typeset -p t_err) > >(t_std=$(cat); typeset -p t_std) )"

        # shellcheck disable=SC2031
        printf "Broken Links:\n%s\n" "$t_std"
        # shellcheck disable=SC2031
        printf "\nErrors:\n%s\n" "$t_err"
        ;;
esac
