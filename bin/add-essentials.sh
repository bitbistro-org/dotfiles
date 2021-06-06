#!/bin/bash
set -e
BASEDIR="$(readlink -f `dirname  $0`/..)";
. $BASEDIR/overlay/.env

if [ -n "$1" ]; then
    LEVEL="$1"
fi

if [ -z "$LEVEL" ]; then
    LEVEL="base"
fi

if [ `id -u` -ne '0' ]; then
    if [ -z $NO_RECURSE ]; then
        exec sudo NO_RECURSE=1 /bin/bash -e "$0" "$LEVEL"
    else
        echo "This must be run as root" >&2 && false
    fi
fi

TEMPFILE="$(mktemp)"
trap '/bin/rm -f -- "$TEMPFILE"' EXIT
apt-config dump | egrep 'APT::Install' | sed -re 's/1/0/g' > $TEMPFILE
export APT_CONFIG="$TEMPFILE"

#apt update
#apt upgrade

case $LEVEL in
    "base")
        apt -y install aptitude aptitude-doc-en
        aptitude -y install "?and(?architecture(native),?or(~prequired))" bash-completion vim-nox git rsync pinentry-tty\
                pinentry-curses_ gpg-agent
    ;;
    "standard")
        aptitude -r install '?and(?architecture(native),?or(~prequired,~pimportant,~pstandard),?not(~v),?not(~slibs))' \
                bsd-mailx exim4-daemon-light bash-completion vim-nox git rsync pinentry-tty gpg-agent \
                pinentry-curses_ '?and(~n^plymouth_,?not(~v))'
        aptitude unmarkauto '?and(?architecture(native),?or(~prequired,~pimportant,~pstandard),?not(~v),?not(~slibs),~i)' \
                bsd-mailx exim4-daemon-light bash-completion vim-nox git rsync pinentry-tty gpg-agent
    ;;
    *)
        echo "Not implemented" >&2
    exit 1
esac

exit 0
