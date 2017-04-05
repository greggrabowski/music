#!/bin/bash

# TO DO filtering folders (exclusion)
# TO DO logging
# TO DO test mode
# TO DO check if all tools are installed
# TO DO handle duplicates

BASE_DIR=`pwd`
LOG_FILE="my_music.log"
SORT_ARTIST=0
SORT_GENRE=0
SORT_FOLDER=0
SORT_ORIG=0
MERGE=0
MERGE_BY_LETTER=0
QUIET=0
PREFIX=""
      
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

function get_group_by_letter {
L=`echo $1 | cut -c 1`
L=`echo "$L" | tr /a-z/ /A-Z/`

if [[ "$L" != "" ]]; then
		echo "$L"
else
    echo "Unknown"       
fi
} 

function get_group_by_head {
L=`echo $1 | cut -c 1`
L=`echo "$L" | tr /a-z/ /A-Z/`

if [[ "$L" == [A-F] ]]; then
		echo "A-F"
elif [[ "$L" == [G-L] ]]; then
    echo "G-L"
elif [[ "$L" == [M-R] ]]; then
    echo "M-R"
elif [[ "$L" == [S-Z] ]]; then
    echo "S-Z"
elif [[ "$L" == [0-9] ]]; then
    echo "0-9"
else
    echo "Unknown"       
fi
} 

function get_group_by_genre {
if [ "$SORT_ORIG" == "1" ]; then
	echo "$1"
else 
  if [ "$1" == "Metal" ]; then
		echo "Metal"
  elif [ "$1" == "Heavy Metal" ]; then
    echo "Metal"
  elif [ "$1" == "Pop" ]; then
    echo "Pop"
  else
    echo "Other"       
  fi
fi
} 

function show_help
{
    echo "Usage: sort_music.sh [-i source directory] [-o target_directory] [-d] [-m] [-h] \
         [-a|f|g] [-t] [-v] [-r] [-q]"
    echo "   -i   scan specified folder for music"
    echo "   -o   target directory where links will be created"
    echo "   -d   display debug messages"
    echo "   -h   display help"
    echo "   -m   merge groups into alphabetical buckets"
  	echo "   -a   sort by artist"
  	echo "   -g   sort by genre"
  	echo "   -f   sort by folder name" 
  	echo "   -l   merge by letter" 
    echo "   -t   test run, don't create links, just display messages"
    echo "   -v   more logging messages"
    echo "   -r   use original categories, do not modify or use high level category"
    echo "   -q   quiet mode"
}

while getopts "hdvo:t?agfi:mrl" opt; do
    case "$opt" in
      h|\?)
        show_help
        exit 0 ;;
      d) DEBUG=1 ;;
      v) VERBOSE=1 ;;
      o) DIR_OUT=$OPTARG ;;
      t) TEST_RUN=1 ;;
      a) SORT_ARTIST=1 ;;
      g) SORT_GENRE=1 ;;
      m) MERGE=1 ;;
      l) MERGE_BY_LETTER=1 ;;
      f) SORT_FOLDER=1 ;;
      i) BASE_DIR=$OPTARG ;;
      r) SORT_ORIG=1 ;;
      q) QUIET=1;
    esac
done


SORT=$((SORT_ARTIST + SORT_GENRE + SORT_FOLDER))
echo $SORT
if [ "$SORT" != "1" ] ; then
   log_i "You can only select one option for sorting"
   exit
fi

if [ "$DIR_OUT" == "" ]; then
  log_i "Output directory missing, exiting ..."
  exit
fi

if [ ! -d "$DIR_OUT" ] ; then
	log_i "Creating directory $DIR_OUT"
	if [ "$TEST_RUN" != 1 ]; then
	  mkdir -p "$DIR_OUT"
	fi
fi


START=`date +%s`
SS=`date`


while read -r dir; do
	
	while read -r file; do
    base=`basename "$dir"` 
    log_d "Basename : $base"
		group=""
		if [ "$SORT_ARTIST" == "1" ]; then
		  artist=`exiftool -artist "$file" | cut -d : -f 2 | cut -c 2-50`
		  group="$artist"
		  log_d "Artist : $group"  
		elif [ "$SORT_FOLDER" == "1" ]; then
		  log_d "Sorting by folder name"
		  #group=`basename "$dir"`  
		else
		  group=`exiftool -genre "$file" | cut -d : -f 2 | cut -c 2-30`
		  group=$(get_group_by_genre "$group")
		fi
		
		
		if [ "$MERGE" == "1" ]; then
			if [ "$SORT_ARTIST" == "1" ]; then
		    PREFIX=$(get_group_by_head "$artist")
		  elif [ "$SORT_FOLDER" == "1" ]; then
			  PREFIX=$(get_group_by_head "$base")
		  fi
		elif [ "$MERGE_BY_LETTER" == "1" ]; then
			if [ "$SORT_ARTIST" == "1" ]; then
		    PREFIX=$(get_group_by_letter "$artist")
		  elif [ "$SORT_FOLDER" == "1" ]; then
			  PREFIX=$(get_group_by_letter "$base")
		  fi		
		fi
		
	  #echo "Group : $group"
	  DIR_GROUP="$DIR_OUT/$PREFIX/$group"
	   	    
	  if [ ! -d "$DIR_GROUP" ] ; then
	    #log_i "Creating directory for group $group: $DIR_GROUP"
	    if [ "$TEST_RUN" != 1 ]; then
	      mkdir -p "$DIR_GROUP"
	    fi
    fi
    
    # TO DO - check if target is not a link 
    
    log_i "Creating link in $DIR_GROUP to dir: $dir"
    if [ "$TEST_RUN" != 1 ]; then
      # create link
      ln -s "$dir" "$DIR_GROUP" &> /dev/null  # redirect errors
	  fi
	   	   
	done < <(find "$dir" -iname "*mp3" -maxdepth 1 -type f | head -n 1)
done < <(find "$BASE_DIR" -depth -type d)


END=`date +%s`

secs=$(($END-$START))
TIME=`printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))`

EE=`date`

log_i "Start: $SS, End: $EE"
log_i "Processing time : $TIME"
