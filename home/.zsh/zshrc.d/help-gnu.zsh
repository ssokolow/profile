# Love you, GNU. But got a bit tired of this conversation pattern:
#
#   % ln -h
#   ln: invalid option -- 'h'
#   Try 'ln --help' for more information.
#
# Don't worry. I fixed you for me.
#
# Eternally yours,
#
# github.com/joepvd
#
# Adapted to not use `eval` by github.com/ssokolow

for util in base64 basename cat chmod chroot cksum comm cp csplit cut dd \
    dirname env factor fmt groups head hostid hostname id install join   \
    ln logname ls md5sum mkdir mkfifo mknod mktemp mv nice nohup nproc   \
    paste pathchk printenv ptx readlink realpath rm rmdir runcon seq     \
    shuf sleep split stat stdbuf stty sum sync tac tail tee timeout tr   \
    tsort tty uname unexpand uniq unlink uptime users wc who whoami yes  \
    $(: and non coreutils :)                                             \
    date
do  function $util {
        if [[ $1 == -h ]]
        then command "$0" --help
        else command "$0" "$@"
        fi
    }
done; unset util
