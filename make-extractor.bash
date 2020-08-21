#!/bin/bash
AS="vasmm68k_mot"
ASARGS="-Ftos -devpac -warncomm -ldots"
TARGETNAME="$(basename $(pwd))"
TARGETDIR="$(pwd)/../../00-hdd/$TARGETNAME"
TARGETPRG="sheetext.prg"

[ ! -d $TARGETDIR ] && echo "Make dir $TARGETDIR" && mkdir -p $TARGETDIR

# proceed
set -x
$AS $ASARGS -o $TARGETPRG sheetext.s
mv $TARGETPRG $TARGETDIR
set +x
