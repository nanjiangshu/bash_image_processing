#!/bin/bash

progname=`basename $0`
size_progname=${#progname}
wspace=`printf "%*s" $size_progname ""` 
usage="
Usage:  $progname [-l LISTFILE] [FILE [FILE...]] 
Description: Print size of image in pixels

Options:
  -l       FILE     Set the fileListFile, one filename per line
  -q                Quiet mode
  -h, --help        Print this help message and exit

Created 2013-01-30, updated 2013-01-30, Nanjiang Shu 
"
PrintHelp(){ #{{{
    echo "$usage"
}
#}}}
IsProgExist(){ #{{{
    # usage: IsProgExist prog
    # prog can be both with or without absolute path
    type -P $1 &>/dev/null \
        || { echo The program \'$1\' is required but not installed. \
        Aborting $0 >&2; exit 1; }
    return 0
}
#}}}
GetImageSize(){ #{{{
    local file="$1"
    local size=`identify -format "%[fx:w*h] %[fx:w]x%[fx:h](w*h)" "$file"`
    printf "%-*s %s\n" $maxFileNameSize "$file" "$size"
} 
#}}}

if [ $# -lt 1 ]; then
    PrintHelp
    exit
fi

isQuiet=0
outpath=./
fileListFile=
fileList=()

isNonOptionArg=0
while [ "$1" != "" ]; do
    if [ $isNonOptionArg -eq 1 ]; then 
        fileList+=("$1")
        isNonOptionArg=0
    elif [ "$1" == "--" ]; then
        isNonOptionArg=true
    elif [ "${1:0:1}" == "-" ]; then
        case $1 in
            -h | --help) PrintHelp; exit;;
            -outpath|--outpath) outpath=$2;shift;;
            -l|--l|-list|--list) fileListFile=$2;shift;;
            -q|-quiet|--quiet) isQuiet=1;;
            -*) echo Error! Wrong argument: $1 >&2; exit;;
        esac
    else
        fileList+=("$1")
    fi
    shift
done

if [ "$fileListFile" != ""  ]; then 
    if [ -s "$fileListFile" ]; then 
        while read line         
        do         
            fileList+=("$line")
        done < $fileListFile
    else
        echo listfile \'$fileListFile\' does not exist or empty. >&2
    fi
fi

IsProgExist identify

maxFileNameSize=0

numFile=${#fileList[@]}
if [ $numFile -eq 0  ]; then
    echo Input not set! Exit. >&2
    exit 1
fi

#Get maxlength of filenames
for ((i=0;i<numFile;i++));do
    file=${fileList[$i]}
    size=${#file}
    if [ $size -gt $maxFileNameSize ]; then
        maxFileNameSize=$size
    fi
done

for ((i=0;i<numFile;i++));do
    file=${fileList[$i]}
    GetImageSize "$file"
done

