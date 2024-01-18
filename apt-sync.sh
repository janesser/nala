#!/bin/bash

display_help() {
	echo "usage: $(basename $0) {fetch|diff|apply} <host1> [host2] [-1|-2] [-i|-u]"
}

CACHE_DIR=$HOME/.cache/apt-sync

if [ ! -d $CACHE_DIR ]; then
	mkdir -p $CACHE_DIR
	echo $CACHE_DIR created.
fi

if [ "$1" == "fetch" ] || [ "$1" == "upgrade" ]; then
	if [ -n "$2" ]; then
		CACHED_FILE=$CACHE_DIR/$2.installed

		PKG_LIST_CMD="LANG=en dpkg-query -W"
		PKG_UPGRADE_CMD="sudo apt upgrade -y"

		if [ "$2" == $(hostname) ] && [ "$1" == "fetch" ]; then
			exec $PKG_LIST_CMD >$CACHED_FILE
			echo $CACHED_FILE stores packages installed.
		elif [ "$2" == $(hostname) ] && [ "$1" == "upgrade" ]; then
			exec $PKG_UPGRADE_CMD
		elif [ "$1" == "fetch" ]; then
			ssh $2 "$PKG_LIST_CMD" >$CACHED_FILE
			echo $CACHED_FILE stores packages installed.
		elif [ "$1" == "upgrade" ]; then
			ssh -t $2 "$PKG_UPGRADE_CMD"
		fi
	else
		echo name a hostname to fetch from or upgrade.
	fi
elif [ "$1" == "diff" ] || [ "$1" == "diff-version" ]; then

	CACHED_FILE1=$CACHE_DIR/$2.installed
	CACHED_FILE2=$CACHE_DIR/$3.installed

	if [ -f $CACHED_FILE1 ] && [ -f $CACHED_FILE2 ]; then
		if [ "$1" == "diff-version" ]; then
			diff --suppress-common-lines -d -y $CACHED_FILE1 $CACHED_FILE2
		elif [ "$1" == "diff" ]; then
			# TODO ignore arm64 vs amd64
			diff --color --suppress-common-lines -d -y <(awk '{print $1;}' $CACHED_FILE1) <(awk '{print $1;}' $CACHED_FILE2)
		fi
	else
		echo $CACHED_FILE1 or $CACHED_FILE2 do not exist, fetch these first.
	fi
elif [ "$1" == "apply" ]; then
	CACHED_FILE1=$CACHE_DIR/$2.installed
	CACHED_FILE2=$CACHE_DIR/$3.installed

	if [ -f $CACHED_FILE1 ] && [ -f $CACHED_FILE2 ]; then
		if [ "$4" == "-1" ] || [ "$4" == "-2"]; then
			if [ "$5" == "-i" ] || [ "$5" == "-u" ]; then
				if [ "$4" == "-1" ] && [ "$5" == "-i" ]; then
					PACKAGES_NOT_INSTALLED=$(comm -2 <(awk '{print $1;}' $CACHED_FILE1) <(awk '{print $1;}' $CACHED_FILE2))
					echo $PACKAGES_NOT_INSTALLED
				elif [ "$4" == "-1" ] && [ "$5" == "-u" ]; then
					PACKAGE_NOT_REQUIRED=$(comm -1 <(awk '{print $1;}' $CACHED_FILE1) <(awk '{print $1;}' $CACHED_FILE2))
					echo $PACKAGES_NOT_REQUIRED
				else
					# TODO
					echo to be implemented.
				fi
			else
				echo "choose to either [-i]nstall missing packages or [-u]ninstall additional packages found."
			fi
		else
			echo "choose to either apply [-1]st or [-2]nd host."
		fi
	else
		echo $CACHED_FILE1 or $CACHED_FILE2 do not exist, fetch these first.
	fi
else
	display_help
fi
