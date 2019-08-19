#!/bin/bash

usage="
Usage:   my_html2image.sh htmlfile-or-url 
  test argument passing
Options:
  -outpath <dir> : set output path, default = ./
  -if      <str> : format of the input source, html or url, default= html
  -of      <str> : set the output format, default=png
                 : format can be gif, jpg,bmp,png,tif,wmf,emf
  -l      <file> : set the fileListFile
  -q             : quiet mode
#html2image options:
   -t <int> : set time out in milliseconds
   -d <int> : set time to delay in milliseconds
   -W <int> : set browser window width
   -H <int> : set browser window height
   -Q <int> : set jpeg quality 1-100
   -x <int> : set right margin, default = 0
   -y <int> : set bottom margin, default = 0

  -h|--help       : print this help message and exit

Created 2011-09-02, updated 2011-09-02, Nanjiang

Examples
    my_html2image.sh www.google.com -if url 
    my_html2image.sh test.html -of jpg -outpath /tmp
    my_html2image.sh -l htmlfilelist -of jpg -outpath out1

Note: 
    direct conversion to png and gif is bad for html2image, a better way is 
    first convert to bmp by html2image and then by the program *convert* to 
    convert them to png or tiff format

"
function PrintHelp()
{
    echo "$usage"
}

function AddAbsolutePath() #$path#{{{
{
    local var=$1
    if [ "${var:0:1}" != "/" ];then
        var=$PWD/$var # add the absolut path
    fi
    echo $var
    return 0
}
#}}}
function IsProgExist()#{{{
# usage: IsProgExist prog
# prog can be both with or without absolute path
{
    type -P $1 &>/dev/null || { echo "The program \"$1\" is required but it's not installed. Aborting $0" >&2; exit 1; }
}
#}}}
function IsPathExist()#{{{
# supply the effective path of the program 
{
    if ! test -d $1; then
        echo "Directory $1 does not exist. Aborting $0" >&2
        exit
    fi
}
#}}}
function MyHtml2Image()#{{{
{
    # first convert to bmp file and then use "convert" to convert them to the
    # desired format 
    local sourcefile=$1
    basename=`basename "$sourcefile"`
    rootname=${basename%.*}
#    ext=${basename##*.}
    if [ "$inputformat" == "html" ]; then
        sourcefile=`AddAbsolutePath $sourcefile`
        targetfile=$outpath/$rootname.$outputformat
        tmptargetfile=$outpath/$rootname.bmp
    else 
        sourcefile=$1
        targetfile=$outpath/$sourcefile.$outputformat
        tmptargetfile=$outpath/$sourcefile.bmp
    fi
    targetfile=`AddAbsolutePath $targetfile`

    current_dir=$PWD
    cd $html2imagePath
    if [ "$isQuiet" != "true" ]; then
        echo "./html2image $html2imageOption $sourcefile $tmptargetfile"
    fi
    ./html2image $html2imageOption $sourcefile $tmptargetfile 
    convert $tmptargetfile $targetfile
    rm -f $tmptargetfile
    cd $current_dir
}
#}}}

if [ $# -lt 1 ]; then
    PrintHelp
    exit
fi

html2imageOption=
html2imagePath=$DATADIR3/usr/share/html2image-x86_64
export LD_LIBRARY_PATH=$html2imagePath:$LD_LIBRARY_PATH

isQuiet=false
outpath=./
fileListFile=
fileList=

inputformat=html
outputformat=png

isNonOptionArg=false
while [ "$1" != "" ]; do
    if [ "$isNonOptionArg" == "true" ]; then 
        fileList="$fileList $1"
        isNonOptionArg=false
    elif [ "$1" == "--" ]; then
        isNonOptionArg=true
    elif [ "${1:0:1}" == "-" ]; then
        case $1 in
            -h | --help) PrintHelp; exit;;
            -outpath|--outpath) outpath=$2;shift;;
            -l|--l|-listfile|--listfile) fileListFile=$2;shift;;
            -if|--if|-informat|--informat) inputformat=$2;shift;;
            -of|--of|-outformat|--outformat) outputformat=$2;shift;;
            -t) html2imageOption="$html2imageOption -t $2";shift;;
            -d) html2imageOption="$html2imageOption -d $2";shift;;
            -W) html2imageOption="$html2imageOption -W $2";shift;;
            -H) html2imageOption="$html2imageOption -H $2";shift;;
            -Q) html2imageOption="$html2imageOption -Q $2";shift;;
            -x) html2imageOption="$html2imageOption -x $2";shift;;
            -y) html2imageOption="$html2imageOption -y $2";shift;;
            -q) isQuiet=true;;
            -*) echo "Error! Wrong argument: $1">&2; exit;;
        esac
    else
        fileList="$fileList $1"
    fi
    shift
done

#check the input output format
case $inputformat in
    html|url)
        if [ "$isQuiet" != "true" ]; then 
            echo "Input format is $inputformat"
        fi
        ;;
    *)
        echo "Input format error ($inputformat)" >&2; exit;;
esac

case $outputformat in
    gif|jpg|bmp|png|tif|wmf|emf)
        if [ "$isQuiet" != "true" ]; then 
            echo "Output format is $outputformat"
        fi
        ;;
    *)
        echo "Output format error ($outputformat)" >&2; exit;;
esac

if [ "$fileList" == "" -a "$fileListFile" == "" ]; then
    echo "Error, input not set! Exit $0" >&2
    exit
fi

IsPathExist $html2imagePath
IsProgExist convert
mkdir -p $outpath

for file in $fileList; do
    MyHtml2Image $file
done

if [ "$fileListFile" != ""  ]; then
    if [ -f "$fileListFile" ] ; then
        for file in $(cat $fileListFile); do 
            MyHtml2Image $file
        done
    else 
        echo "list file $fileListFile does not exist" >&2
    fi
fi

