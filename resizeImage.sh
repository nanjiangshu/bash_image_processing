#!/bin/bash
usage=" 
Usage:  resizeImage.sh file1 file2 ... | -l filelist
the outfile name is $rootname.s<$size>.jpg
if the resolution of the original file is smaller than 1600, just copy the image
Options:
  -h|--help       : print this help message and exit
  -l <file>       : filelist
  -outpath <path> : if outpath is not set, if will be output to the location of the original file
  -N | -origtime  : restore the output file to the original time stamp
  -f              : force overwrite
  -size <int>     : set the resize value, default=1600

Created 2011-03-16, updated 2011-04-03, Nanjiang Shu

Examples:
    resizeImage.sh file1 file2 

Note: there is an option to restore the original time stamp
"
function PrintHelp()
{
    echo "$usage"
}
if [ $# -lt 1 ]; then 
    PrintHelp
    exit
fi
function RestoreOriginalTimeStamp() #origfile, newfile#{{{
{
    local origfile="$1"
    local newfile="$2"
    origtimestamp=`stat -c "%y" "$origfile" | awk -F\. '{print $1}' |     awk -F "[- :]" '{print $1 $2 $3 $4 $5"."  $6 }'`
    if [ ${#origtimestamp} -eq  15 ]; then 
        touch -c -t $origtimestamp "$newfile"
        echo "Change the time stamp to original for file "$newfile""
    else
        echo "Wrong time stamp string $origtimestamp obtained from file $origfile. Ignoring!" >&2

    fi
}
#}}}
function ResizeImage() # file #{{{
{
    local infile="$1"
    local outfile=

    local basename=`basename "$1"`
    local rootname="${basename%.*}"

    if [ "$isOutpathSet" == "false" ]; then
        local dirname=`dirname "$1"`
        outpath=$dirname
    fi

    outfile="$outpath/$rootname.s$size.jpg"

    if [ ! -f "$outfile" -o "$isForceOverWrite" == "true" ]; then
        cp -f  "$infile" "$outfile"
        #get the resolution of image
        originalSize=`identify -format "%[fx:w]" "$outfile"`
        if [ $originalSize -gt $size ]; then 
            mogrify -resize $size "$outfile"
            if [ $isRestoreOrigTime -eq 1 ]; then
                RestoreOriginalTimeStamp "$infile" "$outfile"
            fi
            if [ "$isQuiet" != "true" ]; then
                echo -e "$infile \t ==> $outfile, resized from $originalSize to $size" 
            fi
        else 
            if [ "$isQuiet" != "true" ]; then
                echo -e "$infile \t ==> $outfile, originalSize ($originalSize) <= resize ($size), just copying" 
            fi
        fi
    else
        echo -e "Outfile \"$outfile\" already exists, skipping."
    fi 
}
#}}}

fileListFile=
option=
isForceOverWrite=false
isRestoreOrigTime=0
size=1600
outpath=
fileList=()
isOutpathSet=false
isQuiet=false

isNonOptionArg=false
while [ "$1" != "" ]; do
    if [ "$isNonOptionArg" == "true" ]; then 
        fileList+=("$1")
        isNonOptionArg=false
    elif [ "$1" == "--" ]; then
        isNonOptionArg=true
    elif [ "${1:0:1}" == "-" ]; then
        case $1 in
            -h | --help) PrintHelp; exit;;
            -l) fileListFile=$2;shift;;
            --outpath|-outpath) outpath=$2;isOutpathSet=true;shift;;
            --size|-size) size=$2;shift;;
            -q|--q|--quiet|-quiet) isQuiet=true;throwto=/dev/null;;
            -N|--N|--origtime|-origtime) isRestoreOrigTime=1;;
            -f|--f|--force|-force) isForceOverWrite=true;;
            -*) echo "Error! Wrong argument: $1"; exit;;
        esac
    else
        fileList+=("$1")
    fi
    shift
done

if [ "$isOutpathSet" == "true" ]; then
    mkdir -p "$outpath"
fi

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

numFile=${#fileList[@]}
if [ $numFile -eq 0  ]; then
    echo Input not set! Exit. >&2
    exit 1
fi

for ((i=0;i<numFile;i++));do
    file=${fileList[$i]}
    ResizeImage "$file"
done

