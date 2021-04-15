#! /bin/bash

######Help Information########
function help_info(){
    echo `basename $0`
    echo -e "\t-a <query A file dir>\tfolder for BAM/BED/GFF/VCF file(s) “A”. Each feature in A is compared to B in search of overlaps."
    echo -e "\t-b <query B file(s)>\tOne or more BAM/BED/GFF/VCF file(s) “B”. "
    echo -e "\t-p <prefix>\tprefix for output result"
    echo -e "\t-h \tShow this information"
}

######Get options######
while getopts :a:b:p:h opt
do
    case $opt in
        a)  query_a=$OPTARG
            ;;
        b)  query_b=($OPTARG)
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


######intersecting each sample with reference insertions######
for TE in LINE1 ALU SVA
do
    awk 'BEGIN{OFS="\t"} {print $1,$2,$3,0,0,$6}' ${query_a%/}/${prefix}.${TE}.reference.bed | uniq > ${query_a%/}/${prefix}.${TE}.reference.tmp.bed #将某个transposon对应的"merged reference insertion"转换一下格式，用于intersect
    for b in ${query_b[*]}
    do
        id=`basename ${b}`; id=${id%%.*bed}; outdir=`dirname ${b}`
        grep ${TE} ${b} | awk 'BEGIN{OFS="\t"} {print $1,$2,$3,$4,$5":"$7":"$8,$6}' > query_b.${TE}.tmp.bed #对于每个sample，取相应transposon的insertion，转换一下格式，用于intersect
        bedtools intersect -a ${query_a%/}/${prefix}.${TE}.reference.tmp.bed -b query_b.${TE}.tmp.bed -s -wa -wb -loj -sorted > query_b.${TE}.tmp1.bed #将reference与每个sample进行intersect，需要在同一条链上
        awk 'BEGIN{OFS="\t"} {print $1";"$2";"$3";"$4";"$5";"$6, $7";"$8";"$9";"$10";"$11";"$12}' query_b.${TE}.tmp1.bed > ${outdir}/${id}_x_${prefix}.${TE}.tmp.bed #将intersect的结果转换一下格式，第一列为reference，第二列为intersect的结果，方便筛选"multi-intersect"的结果
        cut -f 1 ${outdir}/${id}_x_${prefix}.${TE}.tmp.bed | uniq -c | awk '{if($1>1){print $2}}' >> ${query_a%/}/${prefix}.${TE}.reference.multi_intersected.bed #对于每个sample的intersect结果，通过第一列的重复情况确认被"multi-intersected"的"reference insertion"，把所有sample中，同一transposon的"multi-intersected reference"合在一起
        rm query_b.${TE}.tmp.bed && rm query_b.${TE}.tmp1.bed
    done
    echo "the_lowest_control" >> ${query_a%/}/${prefix}.${TE}.reference.multi_intersected.bed
done



######filtering out multi intersected (reference)insertion######
for TE in LINE1 ALU SVA
do
    for b in ${query_b[*]}
    do
        id=`basename ${b}`; id=${id%%.*bed}; outdir=`dirname ${b}`
        awk 'BEGIN{OFS="\t"} {if(NR==FNR){a[$1]=$1}else{if($1 in a){split($2,b,";"); print b[1],b[2],b[3],b[4],b[5],b[6]}}}' ${query_a%/}/${prefix}.${TE}.reference.multi_intersected.bed ${outdir}/${id}_x_${prefix}.${TE}.tmp.bed > ${outdir}/${id}_x_${prefix}.${TE}.multi.tmp.bed #根据某个transposon的"multi-intersected reference"，筛选出每个样本初步intersect结果中，"multi-intersect"的记录
        awk 'BEGIN{OFS="\t"} {if(NR==FNR){a[$1]=$1}else{if(!($1 in a)){print $0}}}' ${query_a%/}/${prefix}.${TE}.reference.multi_intersected.bed ${outdir}/${id}_x_${prefix}.${TE}.tmp.bed > ${outdir}/${id}_x_${prefix}.${TE}.bed #根据某个transposon的"multi-intersected reference"，筛选出每个样本初步intersect结果中，"uniq-intersect"的记录
        awk '{if(!($1==".")){print $0}}' ${outdir}/${id}_x_${prefix}.${TE}.multi.tmp.bed > ${outdir}/${id}_x_${prefix}.${TE}.multi.bed #转换一下每个样本"multi-intersect"记录的格式，以便于转换成BigBed格式，在genome browser上查看
    done
done

rm ${query_a%/}/*tmp*
rm ${query_a%/}/*/*tmp*

#nohup ../../../bin/intersect_with_reference.sh -a UMB4638/ -b "UMB4638/*/*.insertion.bed" -p UMB4638 &