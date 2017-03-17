#!/bin/bash
# TO DO input folder
# TO DO filtering folders (exclusion)
# TO DO logging
# TO DO test mode
# TO DO check if all tools are installed

BASE_DIR=`pwd`

function log_i() {
    echo "INFO : $@"	
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


while getopts "hdvo:t?" opt; do
    case "$opt" in
      h|\?)
        show_help
        exit 0 ;;
      d) DEBUG=1 ;;
      v) VERBOSE=1 ;;
      o) DIR_OUT=$OPTARG ;;
      t) TEST_RUN=1 ;;
    esac
done

if [ "$DIR_OUT" == "" ]; then
  log_i "Output directory missing, exiting ..."
  exit
fi

if [ ! -d "$DIR_OUT" ] ; then
	log_i "Creating directory $DIR_OUT"
	mkdir -p "$DIR_OUT"
fi

while read -r line; do
	
	while read -r ff; do
		#echo "FFF : $ff"
		genre=`exiftool "$ff" | grep Genre | cut -d : -f 2 | cut -c 2-30`
	  #log_d   
	  genre=$(get_group_by_genre "$genre")
	  
	  DIR_GENRE="$DIR_OUT/$genre"
	   	    
	  if [ ! -d "$DIR_GENRE" ] ; then
	    log_i "Creating directory for genre $genre: $DIR_GENRE"
	    if [ "$TEST_RUN" != 1 ]; then
	      mkdir -p "$DIR_GENRE"
	    fi
    fi

    ln -s "$line" "$DIR_GENRE" &> /dev/null  # redirect errors
	  # handle duplicates
	   # create link
	   	   
	done < <(find "$line" -iname "*mp3" -maxdepth 1 | head -n 1)
done < <(find "$BASE_DIR" -depth -type d)



