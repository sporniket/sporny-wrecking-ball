#!/bin/bash
AS="vasmm68k_mot"
ASARGS="-Ftos -devpac -warncomm -opt-allbra -nomsg=2054"
TARGETDIR="$(pwd)/build"
TARGETPRG="mk_lvls.prg"

[ ! -d $TARGETDIR ] && echo "Make dir $TARGETDIR" && mkdir -p $TARGETDIR

# proceed
set -x
$AS $ASARGS -o $TARGETPRG mk_lvls.s
mv $TARGETPRG $TARGETDIR
set +x
