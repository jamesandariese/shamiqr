#!/bin/bash

cd "$(dirname "$0")"

BINDIR="$HOME/bin"
mkdir -p "$BINDIR"

cp -a shamiqr.sh "$BINDIR"/shamiqr
cp -a unshamiqr.sh "$BINDIR"/unshamiqr
cp -a qrmost.sh "$BINDIR"/qrmost
