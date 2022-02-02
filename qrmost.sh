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
which gfsplit > /dev/null    || cnf "gfsplit: not found, install libgfsplit or related packages"
which qrencode > /dev/null   || cnf "qrencode: not found, install qrencode or related packages"

[ x"$(echo -n test | base64 | base64 -d)" == xtest ] || cnf "base64 does not work.  install GNU coreutils and make sure base64 is linked to them."

SHARES=5
THRESH=3

USAGE="$0: qrmost [-m min] [-x max] [-s step] [-D] IMG_BIG.jpeg IMG_SMALL.jpeg

-m min        set the minimum tested size
-x max        set the maximum tested size
-s step       set the step size for testing image sizes
-D            enable debug mode (will not delete temp files!)
-h            this message

Attempts to discover the optimum size image for zbarimg to scan."

DEBUG=no
MIN=400
MAX=1200
STEP=100

while getopts hm:x:Ds: f
do
        case $f in
        m)      MIN="$OPTARG";;
        x)      MAX="$OPTARG";;
        s)      STEP="$OPTARG";;
        D)      DEBUG=yes;;
        h)      echo "$USAGE"; exit 0;;
        \?)     echo "$USAGE"; exit 1;;
        esac
done
shift $(( OPTIND - 1 ))

case $# in
    0) echo "$USAGE";echo missing input filename; exit 1;;
    1) ;;
    2) ;;
    *) echo "$USAGE";echo unrecognized arguments; exit 1;;
esac

INPUT="$1"
OUTPUT="$2"

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

cp "$INPUT" "$TD/"
if [ x"$OUTPUT" = x ];then
    FORMAT=png
else
    FORMAT="${OUTPUT##*.}"
    if [ x"$FORMAT" = x"$OUTPUT" ];then
        #if there wasn't a format found, use png.
        FORMAT=png
    fi
fi

SIZE=$MIN

: > "$TD/results.txt"

while [ $SIZE -le $MAX ];do
    echo -n "testing X=${SIZE}... "
    TESTFILE="$TD/test.$SIZE.$FORMAT"
    convert "$INPUT" -resize ${SIZE}x -unsharp 10x10 "$TESTFILE"
    echo "$(zbarimg --raw -Sdisable -Sqrcode.enable -q "$TESTFILE" | grep . | wc -l) $SIZE" >> "$TD/results.txt"
    echo "found $(tail -1 "$TD/results.txt" | cut -d' ' -f1) QR codes"
    SIZE=$(( SIZE + STEP ))
done

if ! (cat "$TD/results.txt" | grep -v '^0 ' > "$TD/available.txt") ;then
    echo "No suitable sizes found."
    exit 1
fi
BEST="$(cat "$TD/available.txt" | grep -v '^0 ' | sort -ns | tail -1 | cut -d' ' -f1)"
grep -E "^${BEST} " "$TD/results.txt" > "$TD/onlybest.txt"
BESTCOUNT="$(wc -l < "$TD/onlybest.txt")"
if [ $BESTCOUNT -eq 1 ];then
    LINE=1
elif [ $BESTCOUNT -eq 0 ];then
    echo "this shouldn't be possible."
    exit 1
else
    LINE="$(awk -v v="$BESTCOUNT" 'BEGIN {print int((v/2)+.5);exit 0}')"
fi
EXACTBEST="$(head -n "$LINE" "$TD/onlybest.txt"|tail -1|cut -d' ' -f2)"
echo "selected X=${EXACTBEST}"

if [ x"$OUTPUT" != x ];then
    echo "saving to $OUTPUT"
    mv "$TD/test.$EXACTBEST.$FORMAT" "$OUTPUT"
fi
