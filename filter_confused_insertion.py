import sys, getopt, re, copy

def make_tag_dic(input_file):
    '''
    初始化一个"字典-列表"嵌套结构：
    字典的key是截取出的"confused insertion mark"
    '''
    confused_tags = {}
    with open(input_file, "r") as in_f:
        for tag in in_f:
            tag = tag.strip()
            confused_tags[tag] = []
    
    return confused_tags

def collect_insertion(input_file, confused_tags):
    '''
    confused_tags为"make_tag_dic"初始化出来的空字典。对于空字典中的每一个mark，添加包
    含这个mark的"combined insertion"，这个"combined insertion"的形式是一个列表，最终
    返回的，是一个"字典-列表-列表"嵌套结构
    '''
    with open(input_file, "r") as in_f:
        for l in in_f:
            l=l.strip()
            for tag in confused_tags:
                if(tag in l):
                    confused_tags[tag].append(l.split())
    
    return confused_tags

def output_confident_insertion(output_file, confused_insertions):
    '''
    confused_insertions为函数collect_insertion返回的"字典-列表-列表"嵌套结构。对于每
    一个"confused insertion mark"对应的"combined insertion"(可能是1个，也可能是2个)，
    如果对应2个insertion，分别计算这两个insertion的"share counts"。根据"share counts"
    的大小来判断保留哪一个insertion，并且输出。

    如果"share counts"相同，则根据其大小来"合并"、"丢弃"或"保留"
    '''
    for tag in confused_insertions:
        if(len(confused_insertions[tag]) == 2):
            sample_counts = len(confused_insertions[tag][0]) - 1
            share_counts_1 = sample_counts - confused_insertions[tag][0].count(".")
            share_counts_2 = sample_counts - confused_insertions[tag][1].count(".")
            
            if(share_counts_1 > share_counts_2):
                confused_insertions[tag].remove(confused_insertions[tag][1])
            if(share_counts_1 < share_counts_2):
                confused_insertions[tag].remove(confused_insertions[tag][0])
            if(share_counts_1 == share_counts_2):
                if(share_counts_1 == 1):
                    confused_insertions[tag][0][0] = confused_insertions[tag][0][0][:-1] + "." #合并时修改第一列的插入链的方向
                    confused_insertions[tag].remove(confused_insertions[tag][1])
                if(share_counts_1 >= sample_counts/2):
                    next
                else:
                    confused_insertions[tag] = []
                    
    with open(output_file, "w") as out_f:
        for tag in confused_insertions:
            if(confused_insertions[tag]):
                for ins in confused_insertions[tag]:
                    ins = "\t".join(ins)
                    print(ins, file=out_f)

def main(argv):
    insertion_file = ""
    tag_file = ""
    out_file = ""
    try:
        #返回值opts是以元组为元素的列表，每个元组的形式为：(选项串, 附加参数)，如：('-i', '192.168.0.1')
        #而返回值args是个列表，其中的元素是那些不含'-'或'--'的参数。
        opts, args = getopt.getopt(argv, "hi:t:o:", ["help", "input=", "output="]) 
    except getopt.GetoptError:
        print('python filter_confused_insertion.py -i <inputfile(combined filtered insertions)> -t <inputfile(confused tags)> -o <outputfile>')
        sys.exit(2)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print('python filter_confused_insertion.py -i <inputfile(combined filtered insertions)> -t <inputfile(confused tags)> -o <outputfile>')
        elif opt in ("-i", "--insertion"):
            insertion_file = arg
        elif opt in ("-t", "--tag"):
            tag_file = arg
        elif opt in ("-o", "--output"):
            out_file = arg
    
    if(insertion_file and tag_file):
        confused_tags = make_tag_dic(tag_file)
        confused_insertions = collect_insertion(insertion_file, confused_tags)
        output_confident_insertion(out_file, confused_insertions)


#argv[0]是脚本的名字，获取参数时，一般不考虑argv[0]
if __name__ == "__main__":
   main(sys.argv[1:])





#confused_tags = make_tag_dic("./UMB4638.LINE1.tmp.confused_reslut")
#confused_insertions = collect_insertion("./UMB4638.LINE1.combined_filtered_result", copy.deepcopy(confused_insertions))
#output_confident_insertion("test_output", tmp_tags)
