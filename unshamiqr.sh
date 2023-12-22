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
which zbarimg > /dev/null    || cnf "zbarimg: not found, install zbar-tools or related packages"

[ x"$(echo -n test | base64 | base64 -d)" == xtest ] || cnf "base64 does not work.  install GNU coreutils and make sure base64 is linked to them."

USAGE="$0: unshamiqr input.jpeg output.txt

Reads shamir shares from an image and attempts to assemble the original information

If you have trouble with an image, try increasing the contrast.
"

DEBUG=no

while getopts D f
do
        case $f in
        D)      DEBUG=yes;;
        \?)     echo "$USAGE"; exit 1;;
        esac
done
shift $(( OPTIND - 1 ))

case $# in
    1) echo missing output filename; exit 1;;
    0) echo missing input filename; exit 1;;
    2) ;;
    *) echo unrecognized arguments; exit 1;;
esac

INPUT="$1"
OUTPUT="$2"

shred="$(which shred)"
rmdir="$(which rmdir)"

[ x"$DEBUG" = xyes ] && shred="echo shred"
[ x"$DEBUG" = xyes ] && rmdir="echo rmdir"
[ x"$DEBUG" = xyes ] && echo "debugging mode on"

TD="$(mktemp -d)"

exit_trap() {
    for f in "$TD"/*;do
        $shred -u "$f"
    done
    $rmdir "$TD"
}
trap "exit_trap" EXIT

zbarimg -q "$INPUT" --raw | grep .| while read -r B64;do
    SHARENO="${B64%%:*}"
    SHARENO="${SHARENO##0}" # these are not octal
    B64="${B64#*:}"
    echo "$B64" |base64 -d > "$(printf %q.%03d "$TD/share" "$SHARENO")"
done

gfcombine -o "$TD/$OUTPUT" "$TD"/share.*
base64 -d "$TD/$OUTPUT" > "$OUTPUT"
