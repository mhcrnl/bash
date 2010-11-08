#!/bin/bash
# URL: http://drzero.skumleren.net/make_movie_screenshots.sh
# Written 21 August 2006, drzero
# Version 1.4, 17 August 2007
# Requirements: Bash, MPlayer, ImageMagick
#
# Changes from 1.3 to 1.4:
#  -- added URL, version information and revision history. Thanks to 
#     haateeteepee for the idea
# Changes from 1.2 to 1.3:
#  -- changed the starting $POS from $INTERVAL to $INTERVAL/2
# Changes from 1.1 to 1.2:
#  -- nicer and friendlier output, even better code structure (thanks again to
#     ericp) and better interval dispersion of screenshots.
# Changes from 1.0 to 1.1:
#  -- nicely redone layout, much saner, thanks to ericp

#############
# Functions #
#############


##
# get_movie_length():
#
# Tries to find out the length in seconds of a movie, using mplayer. The result
# is put in the LENGTH variable.
#
# Parameters:
#   MOVIEFILE   Movie's filename.
##
get_movie_length() {
	local file=$1

	# Find length
	LENGTH=$($MPLAYER -identify -frames 0 -vo null -ao null \
		"$file" | grep '^ID_LENGTH' | sed -e 's:.*=\([0-9]*\).*:\1:')

	# Verify the movie's length by finding a screenshot closest to the end
	# of the movie. This is done because some movies report a length that
	# is beyond the point where a screenshot can be captured.
	local end_found=0
	while [ $end_found -ne 1 ]; do
		grab_screenshot "$file" $LENGTH
		if [ -f "${TMPDIR}/shot.jpg" ]; then
			end_found=1
		else
			let "LENGTH = $LENGTH - 2"
			if [ $LENGTH -le 0 ]; then
				echo "Couldn't find the movie's length"
				exit 1
			fi
		fi
	done
}


##
# grab_screenshot():
#
# Produces a screenshot from a movie at a particular point in time, using
# mplayer. If the image is captured succesfully, it is moved to
# $TMPDIR/shot.jpg.
#
# Parameters:
#   MOVIEFILE   Movie's filename.
#   POS         Position to capture; could be specified in seconds or any other
#               format that mplayer understands
##
grab_screenshot() {
	local file=$1
	local pos=$2

	# Make sure there's no screenshot before creating a new one
	[ -f "$TMPDIR/shot.jpg" ] && rm -f "$TMPDIR/shot.jpg"

	# Sometimes the first frame is grabbed before the seek
	# operation finishes, so grab 2 frames and use the second one
	$MPLAYER -ao null -ss $pos -frames 2 -vo jpeg:outdir="$TMPDIR" \
		"$file" &>/dev/null
	
	rm -f "${TMPDIR}/00000001.jpg"
	[ -f "${TMPDIR}/00000002.jpg" ] && \
		mv -f "${TMPDIR}/00000002.jpg" "${TMPDIR}/shot.jpg"
}


##
# main():
#
# Main function.
##
main() {
	echo -n "Finding the movie's length: "
	get_movie_length "$MOVIEFILE"
    echo "$LENGTH secs"
	
	# Calculate interval
	let "INTERVAL=$LENGTH / $NUMSHOTS"

	# Setup tmp-dir
	local tmpdir_existed
	if [ -d "$TMPDIR" ]; then
		tmpdir_existed=1
	else
		tmpdir_existed=0
		mkdir -p "$TMPDIR"
	fi

	let "POS=$INTERVAL / 2"
	NUM=1

    echo -n "Grabbing $NUMSHOTS screenshots:"
	local filelist=""
	while [ $NUM -le $NUMSHOTS ]; do
		[ $POS -ge $LENGTH ] && let "POS = $LENGTH - 1"

		echo -n " #${NUM}"
		grab_screenshot "$MOVIEFILE" $POS

		mv -f "${TMPDIR}/shot.jpg" "${TMPDIR}/${NUM}.jpg"
		filelist="$filelist ${TMPDIR}/${NUM}.jpg"

		let "POS += $INTERVAL"
		let "NUM += 1"
	done
    echo


	echo "Creating montage.."
	let "rows = $NUMSHOTS / 2"
	$MONTAGE -geometry 200x -tile 2x$rows $filelist "${OUTFILE}"
	echo "Wrote ${OUTFILE}"

	[ $tmpdir_existed -eq 0 ] && rm -fr "$TMPDIR"
}


##
# sanity_checks():
#
# Verifies that some basic requirements are met.
##
sanity_checks() {
	if [ ! -x "$MPLAYER" ]; then
		echo "Required program 'mplayer' not found."
		exit 1
	fi

	if [ ! -x "$MONTAGE" ]; then
		echo "Required program 'montage' not found. Make sure you have"
		echo "imagemagick installed in your system."
		exit 1
	fi

	if [ ! -f "$MOVIEFILE" ]; then
		echo "Movie file '${MOVIEFILE}' not found."
		exit 1
	fi
}


##
# usage():
#
# Displays a short help message and exits.
##
usage() {
	echo "Usage: $(basename $0) [OPTIONS] MOVIEFILE"
	echo "Creates a group of screenshots from a movie file using mplayer"
	echo "and imagemagick."
	echo
	echo "  -d DIR         Use DIR as a temporary directory"
	echo "                 (default is /tmp/screenshots)"
	echo "  -n NUM         Number of images to include in the final montage"
	echo "                 (default is 20)"
	echo "  -o FILE        Output file"

	exit 1
}



######################
# Script Entry Point #
######################


while getopts "d:n:o:" option; do
	case $option in
		d) TMPDIR="$OPTARG" ;;
		n) NUMSHOTS="$OPTARG" ;;
		o) OUTFILE="$OPTARG" ;;
		*) usage ;;
	esac
done
shift $(($OPTIND - 1))

[ $# -lt 1 ] && usage

MONTAGE=$(which montage)
MOVIEFILE="$1"
MPLAYER=$(which mplayer)
NUMSHOTS=${NUMSHOTS:-20}
OUTFILE=${OUTFILE:-$(basename "${MOVIEFILE%.*}_screens.jpg")}
TMPDIR=${TMPDIR:-/tmp/screenshots}

sanity_checks
main

