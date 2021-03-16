#!/bin/bash

######Help Information########
function help_info(){
    echo `basename $0`
    echo -e "\t-l <left fastq(s)>\tleft fastq file(s)."
    echo -e "\t-r <right fastq(s)>\tright fastq file(s)."
    echo -e "\t-I <BWA Index>\tBWA index for genome. Or using -G option."
    echo -e "\t-G <genome>\tname of reference genome. Or using -I option to specify BWA index."
    echo -e "\t-c <int>\tcpu number for BWA"
    echo -e "\t-h \tShow this information"
}

if [ $# -lt 1 ];then
    help_info && exit 1
fi

while getopts ":l:r:I:G:o:c:h" OPTION; do
    case $OPTION in
        l)  LEFT=($OPTARG);;
        r)  RIGHT=($OPTARG);;
        I)  BWA_INDEX=$OPTARG;;
        G)  GENOME=$OPTARG;;
        o)  OUT_PATH=$OPTARG;;
        c)  CPU=$OPTARG;;
        h)  help_info && exit 1;;
        *)  help_info && exit 1;;
    esac
done

PATH_PROG=`dirname ${0}` && PATH_ANNO="/data/tusers/yutianx/tongji2/GitHuB/piSet/annotation/${GENOME}"
[ -z ${BWA_INDEX} ] && BWA_INDEX=${PATH_ANNO}/BWAIndex/genome
[ -z ${OUT_PATH} ] && OUT_PATH=./TEMP2_result
[ -z ${CPU} ] && CPU=8

if [ -z ${PREFIX} ];then
    NUM=0
    for i in ${LEFT[*]}
    do
        PREFIX[$NUM]=`basename ${i%[._]1.f*q*}`
        NUM=$(($NUM + 1))
    done
fi


#############
## process ##
[ ! -d ${OUT_PATH} ] && mkdir ${OUT_PATH}
SAMPLE_INDEX=0

for TEMP_LEFT in ${LEFT[*]}
do 
    echo0 1 "processing for ${PREFIX[${SAMPLE_INDEX}]}"
    date
    OUT_DIR=${OUT_PATH}/${PREFIX[${SAMPLE_INDEX}]} && mkdir ${OUT_DIR}
    mv ${TEMP_LEFT} ${OUT_DIR} && mv ${RIGHT[${SAMPLE_INDEX}]} ${OUT_DIR} #将原始fastq移到输出目录，输出目录最好设置为home下面的目录，防止I/O被占太多
    bwa mem -t ${CPU} ${BWA_INDEX} ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}_1.fastq ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}_2.fastq > ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.sam 2>${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.bwamem.log || \
                    { $echo 0 "Error: bwa mem failed, please check ${OUTDIR}/${PREFIX}.bwamem.log. Exiting..." && exit 1; }
            $echo 2 "transform sam to sorted bam and index it"
            samtools view -bhS -@ ${CPU} ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.sam > ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.bam
            samtools sort -@ ${CPU} -o ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.sorted.bam ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.bam
            rm ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.sam && mv ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.sorted.bam ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.bam
            samtools index -@ ${CPU} ${OUT_DIR}/${PREFIX[${SAMPLE_INDEX}]}.bam
    mv ${OUT_DIR} `dirname ${TEMP_LEFT}`/TEMP2_result #将输出结果放回原本的data目录下，防止占据太多home的内存空间
    SAMPLE_INDEX=$((${SAMPLE_INDEX} + 1))
    date
done