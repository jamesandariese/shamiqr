#!/bin/bash

set -e

logerr() {
    1>&2 echo "$@"
}

log() {
    echo "$@"
}

cnf() {
    logerr "$@"
    exit 1
}

which base64 > /dev/null     || cnf "base64: not found"
which gfsplit > /dev/null    || cnf "gfsplit: not found, install libgfshare-bin or related packages"
which qrencode > /dev/null   || cnf "qrencode: not found, install qrencode or related packages"

[ x"$(echo -n test | base64 | base64 -d)" == xtest ] || cnf "base64 does not work.  install GNU coreutils and make sure base64 is linked to them."

SHARES=5
THRESH=3

USAGE="$0: shamiqr [-n threshold] [-m shares] output.png

Creates qr codes containing the base64 of the password entered,
split into shamir shares.  These qr codes will be saved to a
single image using imagemagick.

  shares:    the number of shares to create for distribution
  threshold: the required number of shares to recover the secret
"

MSG="use unshamiqr\nto expand\nthese secret\nshares\n"

DEBUG=no

while getopts M:m:n:D f
do
        case $f in
        m)      SHARES="$OPTARG";;
        n)      THRESH="$OPTARG";;
        D)      DEBUG=yes;;
        M)      MSG="$OPTARG";;
        \?)     echo "$USAGE"; exit 1;;
        esac
done
shift $(( OPTIND - 1 ))

MSG="$(echo -e "$MSG")"

if [ x"$1" = x ];then
    echo missing output filename
    echo "$USAGE"
    exit 1
fi

if [ $# -gt 1 ];then
    echo "unrecognized arguments"
    exit 1
fi

OUTPUT=$1

TD="$(mktemp -d)"

shred="$(which shred)"
rmdir="$(which rmdir)"

[ x"$DEBUG" = xyes ] && shred="echo shred"
[ x"$DEBUG" = xyes ] && rmdir="echo rmdir"
[ x"$DEBUG" = xyes ] && echo "debugging mode on"

exit_trap() {
    for f in "$TD"/*;do
        $shred -u "$f"
    done
    $rmdir "$TD"
}

trap "exit_trap" EXIT

if tty -s;then
    echo -n "Password: "
    read -r -s password
    echo                    # clear the line after read -s
    echo "$password" | base64 > "$TD"/password.txt 
else
    base64 > "$TD"/password.txt
fi


gfsplit -n "$THRESH" -m "$SHARES" "$TD"/password.txt "$TD"/shamiqr-shares
for f in "$TD"/shamiqr-shares.???;do
    echo -n "${f##*.}:" > "$f.b64"
    base64 "$f" >> "$f.b64"
    qrencode -s 5 -t PNG -r "$f.b64" -l H -o "$f.png"
done

# strip any final newline and then add one to ensure wc -l works.
NL='
'
MSG="${MSG%$NL}
"
LINES="$(echo -n "$MSG" | wc -l)"

HEIGHT=$(( 12 * LINES + 12))
convert -size 120x$HEIGHT xc:white -pointsize 12 -fill black -draw 'text 30,16 "'"$MSG"'"' "$TD/00000-instr.png"
CONVERTOPTS="$(printf ' %q' "$TD"/*.png) -append"

echo "writing to $OUTPUT"
convert $CONVERTOPTS "$OUTPUT"

