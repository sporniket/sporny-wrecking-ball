#!/bin/bash
AS="vasmm68k_mot"
ASARGS="-Ftos -devpac -warncomm -ldots"
TARGETDIR="$(pwd)/build"
TARGETPRG="font_ext.prg"

[ ! -d $TARGETDIR ] && echo "Make dir $TARGETDIR" && mkdir -p $TARGETDIR

# proceed
set -x
$AS $ASARGS -o $TARGETPRG font_ext.s
mv $TARGETPRG $TARGETDIR
set +x
