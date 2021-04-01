#! /bin/bash

######Help Information########
function help_info(){
    echo `basename $0`
    echo -e "\t-b <bulk id>\tid of the bulk sample"
    echo -e "\t-d <input dir>\tdirectory of the '-p' specified prefix"
    echo -e "\t-p <prefix>\tprefix for output result"
    echo -e "\t-h \tShow this information"
}

######Get options######
while getopts :b:d:p:h opt
do
    case $opt in
        b)  bulk=$OPTARG
            ;;
        d)  directory=$OPTARG
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


######Combine and filteration######
for TE in LINE1 ALU SVA
do
    ##对于每种transposon，根据reference insertion，将所有样本的"uniq-intersect"记录合并起来，构建一个matrix，行表示insertion，列表示sample。以便后续筛选
    cut -f 1 ${directory%/}/${bulk}/${bulk}_x_${prefix}.${TE}.bed > ${directory%/}/${prefix}.${TE}.combined_result #把bulk sample的第一列(也就是reference的那一列)拿出来，以便后续的合并
    header='reference'
    
    for i in ${directory%/}/*/*_x_${prefix}.${TE}.bed
    do
        id=`basename ${i}`; id=${id%%_*}; header=${header}"\t"${id}
        join -t $'\t' ${directory%/}/${prefix}.${TE}.combined_result ${i} > ${directory%/}/tmp #通过join进行合并，并用制表符"\t"分隔
        mv ${directory%/}/tmp ${directory%/}/${prefix}.${TE}.combined_result
    done
    
    awk '{gsub(/\.;-1;-1;\.;-1;\./, "."); print $0}' ${directory%/}/${prefix}.${TE}.combined_result > ${directory%/}/tmp #转换一下合并结果的格式，将空的记录转换成"."，以便观察和筛选
    mv ${directory%/}/tmp ${directory%/}/${prefix}.${TE}.combined_result
    python /data/tusers/zhongrenhu/for_TE_and_sSNV/bin/filteration.py -i ${directory%/}/${prefix}.${TE}.combined_result -o ${directory%/}/${prefix}.${TE}.combined_filtered_result #调用filter_confident_insertion.py进行筛选

    ##对于能够通过筛选的"confused insertion"进行处理
    grep -Po '_[0-9]+_[0-9]+_[0-9]+_' ${directory%/}/${prefix}.${TE}.combined_filtered_result | sort -u > ${directory%/}/${prefix}.${TE}.tmp.confused_result #根据特定的标记筛选出"confused insertion"并截取出作为标记的那一部分
    grep -v -P '_[0-9]+_[0-9]+_[0-9]+_' ${directory%/}/${prefix}.${TE}.combined_filtered_result | sort -u > ${directory%/}/${prefix}.${TE}.tmp.confident_result #根据特定的pattern筛选出"confident insertion"
    python /data/tusers/zhongrenhu/for_TE_and_sSNV/bin/filter_confused_insertion.py -i ${directory%/}/${prefix}.${TE}.combined_filtered_result -t ${directory%/}/${prefix}.${TE}.tmp.confused_results -o ${directory%/}/${prefix}.${TE}.tmp.filtered.confused_result
    cat ${directory%/}/${prefix}.${TE}.tmp.confident_result ${directory%/}/${prefix}.${TE}.tmp.filtered.confused_result | sort -u > ${directory%/}/${prefix}.${TE}.combined_filtered_result
    sed -i 1i"${header}" ${directory%/}/${prefix}.${TE}.combined_filtered_result
    rm ${directory%/}/*tmp*
done

#nohup ../../../bin/combine_and_filteration.sh -b SRR2141570 -d ./UMB4638/ -p UMB4638 &