#!/bin/bash
AS="vasmm68k_mot"
ASARGS="-Ftos -devpac -warncomm -ldots"
TARGETDIR="$(pwd)/build"
TARGETPRG="check_hw.prg"

[ ! -d $TARGETDIR ] && echo "Make dir $TARGETDIR" && mkdir -p $TARGETDIR

# proceed
set -x
$AS $ASARGS -o $TARGETPRG check_hw.s
mv $TARGETPRG $TARGETDIR
set +x
