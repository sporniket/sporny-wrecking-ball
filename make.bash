#!/bin/bash
AS="vasmm68k_mot"
ASARGS="-Ftos -devpac -warncomm -opt-allbra -nomsg=2054"
TARGETNAME="swb"
TARGETDIR="$(pwd)/build"
TARGETPRG="${TARGETNAME}.prg"

[ ! -d $TARGETDIR ] && echo "Make dir $TARGETDIR" && mkdir -p $TARGETDIR

# proceed
set -x
$AS $ASARGS -o $TARGETPRG _master.s
mv $TARGETPRG $TARGETDIR
set +x
