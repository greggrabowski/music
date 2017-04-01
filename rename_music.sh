#!/bin/bash

# TO DO check if all tools are installed

BASE_DIR=`pwd`
LOG_FILE="my_music.log"
SORT_ARTIST=0
SORT_GENRE=0
SORT_FOLDER=0
SORT_ORIG=0
MERGE=0
QUIET=0
FOLDER=0
FILE=0
      
function log_ {
    NUM=`echo "${BASH_LINENO[*]}" | cut -f2 -d ' ' `
    DATE=`date "+%Y-%m-%d% %H:%M:%S"`
    LOG_TXT="$DATE : $NUM : $@"
	if [ "$QUIET" != "1" ] ; then
	  echo -e "$LOG_TXT"
	fi
	if [ "$LOG_FILE" != "" ] ; then
		echo -e "$LOG_TXT" >> $LOG_FILE
	fi
}   

function nlog {

if [ "$1" == "I" ]; then
  if [ "$VERBOSE" ==  1 ]; then
    log_ "INFO : ${@:2}"
  fi
elif [ "$1" == "D" ]; then
  if [ "$DEBUG" == 1 ] ; then
    log_ "DEBUG : ${@:2}"
  fi
else
  log_ "$@"
fi
}

function log_i() {
    log_ "INFO : $@"	
}

function log_v() {
  if [ "$VERBOSE" ==  "1" ] ; then
    log_ "INFO : $@"	
  fi
}

function log_d {
	if [ "$DEBUG" = 1 ] ; then
      log_ "DEBUG : $@"
    fi
}  

function show_help
{
    echo "Usage: rename_music.sh [-i source directory] [-d] [-h] [-t] [-v] [-q] [-f]"
    echo "   -i   scan specified folder for music"
    echo "   -d   display debug messages"
    echo "   -h   display help"
    echo "   -t   test run, don't change names, just display messages"
    echo "   -v   more logging messages"
    echo "   -q   quiet mode"
    echo "   -f   rename folder to format %artist% - %album%"
    echo "   -s   rename file/song to format %number% - %title% - %artist% - %album%"
}

while getopts "hdvt?qi:fs" opt; do
    case "$opt" in
      h|\?)
        show_help
        exit 0 ;;
      d) DEBUG=1 ;;
      v) VERBOSE=1 ;;
      t) TEST_RUN=1 ;;
      i) BASE_DIR=$OPTARG ;;
      q) QUIET=1;;
      f) FOLDER=1;;
      s) FILE=1;;
    esac
done


START=`date +%s`
SS=`date`
    
while read -r dir; do
	
	FILE_NUM=0
	SAME_ARTIST=1
	SAME_ALBUM=1
	artist=""
	album=""
	
	while read -r file; do
	
	  FILE_NUM=$(($FILE_NUM+1))	
    base=`basename "$dir"` 

		num=$((10#`exiftool -s3 -track "$file" | cut -f1 -d"/"`))

		title=`exiftool -s3 -title "$file"`
		artist=`exiftool -s3 -artist "$file"`
		album=`exiftool -s3 -album "$file" `  
			
		ext=${file##*.}

    if [ $FILE_NUM -gt 1 ]; then
      if [ "$prev_artist" != "$artist" ] ; then
        SAME_ARTIST=0
      fi
      if [ "$prev_album" != "$album" ] ; then
        SAME_ALBUM=0
      fi
    fi

    prev_album="$album"
    prev_artist="$artist"
        
		if [ "$FILE" == 1 ]; then
		  name=`printf "%02d - %s - %s - %s.%s\n" "$num" "$title" "$artist" "$album" "$ext"`
		  log_i "Renaming $file -> $name"
		  if [ "$TEST_RUN" != 1 ]; then
		    mv "$file" "$name"
		  fi
     fi
	   	   
	done < <(find "$dir" -iname "*mp3" -maxdepth 1 -type f)
	
	
  log_d "$dir : SAME_ARTIST = $SAME_ARTIST, FILE_NUM=$FILE_NUM"
  if [ "$FOLDER" == 1 ] && [ "$FILE_NUM" -gt 0 ] && [ "$SAME_ARTIST" -eq 1 ] && [ "$SAME_ALBUM" -eq 1 ]; then

    if [ "$artist" != "" ] && [ "$album" != "" ]; then
      new_dir="${dir%/*}/$artist - $album"
	    log_i "Renaming dir $dir -> $new_dir"
	    if [ "$TEST_RUN" != 1 ]; then
		    mv "$dir" "$artist - $album"
		   fi
		else
		  log_i "Missing artist or album tag"
		fi
	fi
done < <(find "$BASE_DIR" -depth -type d)


END=`date +%s`

secs=$(($END-$START))
TIME=`printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))`

EE=`date`

log_i "Start: $SS, End: $EE"
log_i "Processing time : $TIME"
