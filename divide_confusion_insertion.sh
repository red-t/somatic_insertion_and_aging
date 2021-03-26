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
    outdir=`dirname ${bed}`
    grep "," ${bed} > ${outdir%/}/tmp.confused.bed
    grep -v "," ${bed} > ${outdir%/}/tmp.convinced.bed
    python /data/tusers/zhongrenhu/for_TE_and_sSNV/bin/divide_confusion_insertion.py -i ${outdir%/}/tmp.confused.bed -o ${outdir%/}/tmp.filtered.confused.bed
    cat ${outdir%/}/tmp.convinced.bed ${outdir%/}/tmp.filtered.confused.bed | sort -k1,1 -k2,2n > ${bed}
    rm ${outdir%/}/*tmp* && rm *tmp*
done



#nohup ../../../bin/divide_confusion_insertion.sh -b "UMB4638/*/*.insertion.bed" &