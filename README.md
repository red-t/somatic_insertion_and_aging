# Transposon somatic insertion and aging

## How to filter out somatic insertions from TEMP2 result?
### Step1: Dividing confused insertions
`divide_confused_insertion.sh`
`        -b <beds>       transposon insertions in BED format`
`        -h      Show this information`

`/data/tusers/zhongrenhu/for_TE_and_sSNV/bin/divide_confused_insertion.sh -b "UMB4638/*/*.insertion.bed`

### Step2: Creating reference insertion
`merge_multi_insertion.sh
        -b <bed(s)>     Insertion files in BED format
        -p <prefix>     prefix for output result.(prefix should belong to one donor)
        -h      Show this information

/data/tusers/zhongrenhu/for_TE_and_sSNV/bin/merge_multi_insertion.sh -p UMB4638 -b "UMB4638/*/*.insertion.bed*"`

### Step3: Intersecting each sample with reference
`intersect_with_reference.sh
        -a <query A file dir>   folder for BAM/BED/GFF/VCF file(s) “A”. Each feature in A is compared to B in search of overlaps.
        -b <query B file(s)>    One or more BAM/BED/GFF/VCF file(s) “B”.
        -p <prefix>     prefix for output result
        -h      Show this information

/data/tusers/zhongrenhu/for_TE_and_sSNV/bin/intersect_with_reference.sh -a UMB4638/ -b "UMB4638/*/*.insertion.bed" -p UMB4638 &`

### Step4: Combining Intersection result and filteration
`combine_and_filteration.sh
        -b <bulk id>    id of the bulk sample
        -d <input dir>  directory of the '-p' specified prefix
        -p <prefix>     prefix for output result
        -h      Show this information

/data/tusers/zhongrenhu/for_TE_and_sSNV/bin/combine_and_filteration.sh -b SRR2141570 -d ./UMB4638/ -p UMB4638`
