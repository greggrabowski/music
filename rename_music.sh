#!/bin/bash

# TO DO check if all tools are installed
# TO DO count moved dir/changeg files

# TO DO mindepth depending on the option
# TO DO do not create duplicate if renaming in same root folder

BASE_DIR=`pwd`
DIR_OUT="$BASE_DIR"
DIRO=0
LOG_FILE="my_music.log"
SORT_ARTIST=0
SORT_GENRE=0
SORT_FOLDER=0
SORT_ORIG=0
MERGE=0
QUIET=0
FOLDER=0
FILE=0
CONVERT=0
START=`date +%s`
LOG_DATE=`+%y_%m_%d_%H_%M_%S`
LOG_FILE="my_music_$LOG_DATE.log"
MIN_DEPTH=1
      
function log_ {
    NUM=`echo "${BASH_LINENO[*]}" | cut -f2 -d ' ' `
    DATE=`date "+%Y-%m-%d %H:%M:%S"`
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
    echo "   -o   move renamed files/dirs to target_directory"
    echo "   -c   convert mpc,flac files into mp3"
    echo "   -l   write to log file"
}

while getopts "hdvt?qi:fso:cl" opt; do
    case "$opt" in
      h|\?)
        show_help
        exit 0 ;;
      d) DEBUG=1 ;;
      v) VERBOSE=1 ;;
      t) TEST_RUN=1 ;;
      i) BASE_DIR=$OPTARG ;;
      o) DIRO=1;
         DIR_OUT=$OPTARG ;;
      q) QUIET=1;;
      f) FOLDER=1;;
      s) FILE=1;;
    esac
done


if [ ! -d "$DIR_OUT" ] ; then
	log_i "Creating directory $DIR_OUT"
	if [ "$TEST_RUN" != 1 ]; then
	  mkdir -p "$DIR_OUT"
	fi
fi

# if we are renaming file only search for files starting from the root dir => MIN_DEPTH=0
if [ "$FILE" == "1" ]; then 
  MIN_DEPTH=0
fi
# if there is no explicit target defined
if [ "$DIR0" != "1" ]; then 
  MIN_DEPTH=0
fi



START=`date +%s`
SS=`date`
    
while read -r dir; do
	
	FILE_NUM=0
	SAME_ARTIST=1
	SAME_ALBUM=1
	artist=""
	album=""
	prev_artist=""
	prev_album=""	
	MOVE_IF_ALL_TAGS=1
	while read -r file; do
	
	  
	  FILE_NUM=$(($FILE_NUM+1))	
    base=`basename "$dir"` 

		#num=$((10#`exiftool -s3 -track "$file" | cut -f1 -d"/"`))
		num=`exiftool -s3 -track "$file"`
		#[[ -n ${myvar//[0-9]} ]] || echo All Digits
    if [ -z "${num##*[!0-9]*}" ]; then
      num=`exiftool -s3 -tracknumber "$file"`
      if [ -z "${num##*[!0-9]*}" ]; then
        log_d "Can't find track number in the tags"
        num="00"
      fi
    fi

		title=`exiftool -s3 -title "$file"`
		artist=`exiftool -s3 -albumartist "$file"`
		
		if [ -z "$artist" ]; then
			artist=`exiftool -s3 -artist "$file"`
    fi
    
		album=`exiftool -s3 -album "$file" `  
		
		if [ -z "$album" ]; then
      album=`exiftool -s3 -albumtitle "$file"`
    fi
    		
		ext=${file##*.}
    
    if [ -z "$artist" ]; then
      SAME_ARTIST=0
    fi
    if [ -z "$album" ]; then
      SAME_ALBUM=0
    fi
    
    if [ $FILE_NUM -gt 1 ]; then
      if [ "$prev_artist" != "$artist" ] ; then
        SAME_ARTIST=0
      fi
      if [ "$prev_album" != "$album" ] ; then
        SAME_ALBUM=0
      fi
    fi

    if [ "$CONVERT" == 1 ]; then
      if [ "$ext" == "flac" ]; then
        #Convert flac to mp3
        OUTF="${a[@]/%flac/mp3}"
        num=`exiftool -s3 -tracknumber "$file"`
        flac -c -d "$file" | lame -V0 --add-id3v2 --pad-id3v2 --ignore-tag-errors \
           --ta "$artist" --tt "$title" --tl "$album"  --tg "$genre" \
          --tn "$tracknumber" - "$OUTF"
        file="$OUTF"
      fi
    fi

#alias flac2mp3='for f in *.flac; do flac -cd "$f" | lame -b 320 - "${f%.*}".mp3; done'

    
    prev_album="$album"
    prev_artist="$artist"
        
		if [ "$FILE" == 1 ]; then
		  if [ ! -z "$title" ]; then
		    loc=`dirname "$file"`
		    name=`printf "%02d - %s - %s - %s.%s\n" "${num#0}" "$title" "$artist" "$album" "$ext"`
		  
		    name=`echo ${name//\//\ }`
        name=`echo ${name//\:/\ }`
      
		    loc="$loc/$name"
		    log_i "Renaming $file -> $loc"
		    if [ "$TEST_RUN" != 1 ]; then
		      mv "$file" "$loc"
		    fi
		  else
		    log_i "File $file doesn't have title tag"
		  fi
    fi
	   	   
	done < <(find "$dir" \( -iname "*.mp3" -or -iname "*.flac" -or -iname "*.ogg" -or \
	       -iname "*.mpc" -or -iname "*.wma" -or -iname "*.wav" \) -maxdepth 1 -type f)
  
  
  log_d "$dir : SAME_ARTIST = $SAME_ARTIST, FILE_NUM=$FILE_NUM"
  if [ "$FOLDER" == 1 ] && [ "$FILE_NUM" -gt 0 ]; then
    if [ "$SAME_ARTIST" -eq 1 ] || [ "$SAME_ALBUM" -eq 1 ]; then
      if [ "$SAME_ARTIST" -eq 1 ] && [ "$SAME_ALBUM" -eq 1 ]; then     
        new_name="$artist - $album"
      elif [ "$SAME_ARTIST" -eq 1 ]; then
        new_name="$artist"
      else [ "$SAME_ALBUM" -eq 1 ]
        new_name="$album"
      fi
        
      new_name=`echo ${new_name//\//\ }`
      new_name=`echo ${new_name//\:/\ }`
      
      if [ "$DIRO" == 1 ]; then
         new_dir="$DIR_OUT/$new_name"
      else
        new_dir="${dir%/*}/$new_name"
      fi
 		
      # if exists increase version or overwrite
      if [ -d "$new_dir" ] ; then
       # if [ "$dir" != "$new_dir" ]; then
          # do it only if 
          date=`date`
	        new_dir="$new_dir ($date)"
	        if [ "$TEST_RUN" != 1 ]; then
	          mkdir -p "$new_dir"
	        fi
	      #fi
      fi     
        
	    log_i "Renaming dir $dir -> $new_dir"
	    if [ "$TEST_RUN" != 1 ]; then
		    mv "$dir" "$new_dir"
		  fi
		else
		  log_i "Missing or mixed album tags (same album: $SAME_ARTIST, same artist: $SAME_ALBUM) in dir : $dir"
		fi
	fi
done < <(find "$BASE_DIR" -mindepth "$MIN_DEPTH" -type d )


END=`date +%s`

secs=$(($END-$START))
TIME=`printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))`

EE=`date`

log_i "Start: $SS, End: $EE"
log_i "Processing time : $TIME"
