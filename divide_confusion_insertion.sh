#! /bin/bash

######Help Information########
function help_info(){
    echo `basename $0`
    echo -e "\t-b <beds>\ttransposon insertions in BED format"
    echo -e "\t-h \tShow this information"
}

######Get options######
while getopts :b:h opt
do
    case $opt in
        b)  BEDs=($OPTARG)
            ;;
        h)  help_info && exit 1
            ;;
        '?')  echo "$0: invalid option -${OPTARG}" >&2
              echo "refer to the help information with -h option, i.e. $0 -h"
            ;;
        esac
done


######Divide######
for bed in ${BEDs[*]}
do
    python /data/tusers/zhongrenhu/for_TE_and_sSNV/bin/divide_confusion_insertion.py -i ${bed} -o tmp.bed
    mv tmp.bed ${bed}
done