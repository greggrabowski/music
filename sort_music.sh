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
      
function log_ {
    NUM=`echo "${BASH_LINENO[*]}" | cut -f2 -d ' ' `
    DATE=`date "+%Y-%m-%d% %H:%M:%S"`
    LOG_TXT="$DATE : $NUM : $@"
	
	echo -e "$LOG_TXT"
	
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

function get_group_by_head {
L=`echo $1 | cut -c 1`
L=`echo "$L" | tr /a-z/ /A-Z/`

if [[ "$L" == [A-D] ]]; then
		echo "A-D"
elif [[ "$L" == [E-H] ]]; then
    echo "E-H"
elif [[ "$L" == [I-Z] ]]; then
    echo "I-Z"
else
    echo "Unknown"       
fi
} 

function get_group_by_genre {
if [ "$1" == "Metal" ]; then
		echo "Metal"
elif [ "$1" == "Heavy Metal" ]; then
    echo "Metal"
elif [ "$1" == "Pop" ]; then
    echo "Pop"
else
    echo "Other"       
fi
} 


while getopts "hdvo:t?agfi:" opt; do
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
      f) SORT_FOLDER=1 ;;
      i) BASE_DIR=$OPTARG ;;
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
	mkdir -p "$DIR_OUT"
fi


START=`date +%s`
SS=`date`


while read -r line; do
	
	while read -r ff; do
    base=`basename "$line"` 
    echo "Basename : $base"
		if [ "$SORT_ARTIST" == "1" ]; then
		  artist=`exiftool "$ff" | grep Artist | cut -d : -f 2 | cut -c 2-50`  
	  
	    group=$(get_group_by_head "$artist")	  
		  group="$group/$artist"
		elif [ "$SORT_FOLDER" == "1" ]; then
		  folder=`basename "$line"`  
	  
	    group=$(get_group_by_head "$folder")	  
		  group="$group/$folder"
		else
		  genre=`exiftool "$ff" | grep Genre | cut -d : -f 2 | cut -c 2-30`
		  group=$(get_group_by_genre "$genre")
		fi
		
	  #echo "Group : $group"
	  DIR_GROUP="$DIR_OUT/$group"
	   	    
	  if [ ! -d "$DIR_GROUP" ] ; then
	    #log_i "Creating directory for group $group: $DIR_GROUP"
	    if [ "$TEST_RUN" != 1 ]; then
	      mkdir -p "$DIR_GROUP"
	    fi
    fi
    log_i "Creating link to directory : $line"
    
    # create link
    ln -s "$line" "$DIR_GROUP" &> /dev/null  # redirect errors
	  
	   	   
	done < <(find "$line" -iname "*mp3" -maxdepth 1 | head -n 1)
done < <(find "$BASE_DIR" -depth -type d)


END=`date +%s`

secs=$(($END-$START))
TIME=`printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))`

EE=`date`

log_i "Start: $SS, End: $EE"
log_i "Processing time : $TIME"
