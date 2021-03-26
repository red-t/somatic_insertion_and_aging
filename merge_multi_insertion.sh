#! /bin/bash

######Help Information########
function help_info(){
    echo `basename $0`
    echo -e "\t-b <bed(s)>\tInsertion files in BED format"
    echo -e "\t-p <prefix>\tprefix for output result.(prefix should belong to one donor)"
    echo -e "\t-h \tShow this information"
}

######Get options######
while getopts :b:p:h opt
do
    case $opt in
        b)  bed_files=($OPTARG)
            ;;
        p)  prefix=$OPTARG
            ;;
        h)  help_info && exit 1
            ;;
        '?')  echo "$0: invalid option -${OPTARG}" >&2
              echo "refer to the help information with -h option, i.e. $0 -h"
            ;;
        esac
done

######Extract specific transposon insertions from each sample, and then merge######
#对于不同的transposon，分别从各样本中筛选相应的insertion，进行merge，构建相应的reference merged insertion
for TE in LINE1 ALU SVA
do
    for bed in ${bed_files[*]}
    do
        grep ${TE} ${bed} >> ${prefix}.${TE}.tmp.bed #从同一个供体的每个sample的insertion.bed文件中，提取相应transposon的所有insertion，合在一起。
    done
    sort -k1,1 -k2,2n ${prefix}.${TE}.tmp.bed > ${prefix}.${TE}.tmp.sorted.bed
    bedtools merge -i ${prefix}.${TE}.tmp.sorted.bed -d 50 -s -c 4,5,6,7 -o distinct,collapse,distinct,collapse -delim "|" > ${prefix}.${TE}.tmp.bed #将某个transposon的所有insertion merge成"reference insertion"，并保留第4、5、6、7列的信息
    sort -k1,1 -k2,2n ${prefix}.${TE}.tmp.bed | uniq > tmp.bed && mv tmp.bed ${prefix}/${prefix}.${TE}.reference.bed
done

rm *tmp*


#nohup ../../../bin/merge_multi_insertion.sh -p UMB4638 -b "UMB4638/*/*.insertion.bed*" &