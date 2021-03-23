import sys, getopt

class Confusing_insertion():
    '''这是一个用于模拟一条confusing insertion的类：
        形参ins_list即记录一个insertion的list；
        形参out_file即输出文件对象。'''
    def __init__(self, ins_list, out_file):
        self.ins_list = ins_list
        self.ins_dic = {}
        self.out_file = out_file
    
    def mkdic(self):
        '''用于创建self.ins_dic的函数：
            目的是创建一个字典--字典--列表的镶嵌字典。最外层字典是以转座子ID为key；第二层字典是以正负号为key；
            第三层的列表记录这个insertion中符合上层条件的所有fragment(即第四列信息)'''
        colum4 = self.ins_list[3].split(",")
        for frag in colum4:
            te = frag.split(":")[0]
            if (te not in self.ins_dic):
                self.ins_dic[te] = {"+":[], "-":[]}
                self.ins_dic[te][frag[-1]].append(frag)
            else:
                self.ins_dic[te][frag[-1]].append(frag)
    
    def multi_te_mode(self):
        '''将第四列中有多种转座子片段的insertion，按照转座子类型拆分insertion'''
        new_freq = float(self.ins_list[4])/len(self.ins_dic) #frequency按照转座子种类数进行均分
        new_sr = float(self.ins_list[7])/len(self.ins_dic) #support reads同上
        for te in self.ins_dic: #对于每种transposon，各自判定新的插入链(第六列)、合并新的的插入片段(第四列)、并且输出到文件当中
            new_strand = ""
            if(not self.ins_dic[te]["-"]): #根据对应转座子、对应负链的列表是否为空，来判断新的插入链是否为"+"
                new_strand = "+"
            if(not self.ins_dic[te]["+"]):
                new_strand = "-"
            if(self.ins_dic[te]["+"] and self.ins_dic[te]["-"]):
                new_strand = "."
            
            new_frag = ""
            tmp = self.ins_dic[te]["+"] + self.ins_dic[te]["-"]
            new_frag = ",".join(tmp) #将正负链中的fragment都拼接起来，作为新的第四列

            new_insertion = "\t".join(self.ins_list[:3]) + "\t" + "\t".join([new_frag, str(new_freq), new_strand, self.ins_list[6], str(new_sr)]) + "\t" + "\t".join(self.ins_list[8:]) #拼接一种转座子相应的"new insertion"
            print(new_insertion, file=self.out_file)
    
    def single_te_same_strand(self, input_dic):
        '''处理第四列只有一种转座子，并且都处于同一条链上的情况。input_dic与self.inse_dic结构相同，
            但是最外层字典只有一种转座子，第二层字典，要么正链对应的列表为空，要么负链对应的列表为空'''
        te = list(self.ins_dic.keys())[0]
        if(input_dic[te]["+"]):
            strand = "+"
        else:
            strand = "-"

        if(te == "LINE1"):
            frag_len = [] #对于LINE1，计算每个插入片段的长度
            for frag in input_dic[te][strand]:
                frag = frag.split(":")
                frag_len.append(float(frag[2])-float(frag[1]))
            
            new_frag = zip(frag_len, input_dic[te][strand]) #将插入片段长度与插入片段列表拼接起来，组合成"列表-元组"嵌套结构，以便排序
            sorted_new_frag = [x for _,x in sorted(new_frag, reverse=True)] #按照插入片段长度对"列表-元组"进行排序，并且提取排序后的插入片段列表
            sorted_new_frag = ",".join(sorted_new_frag)
            new_insertion = "\t".join(self.ins_list[:3]) + "\t" + "\t".join([sorted_new_frag, self.ins_list[4], strand]) + "\t" + "\t".join(self.ins_list[6:])
            print(new_insertion, file=self.out_file)
        else:
            new_frag = ",".join(input_dic[te][strand]) #对于非"LINE1" insertion，根据input_dic中的信息拼接第四列，进而输出
            new_insertion = "\t".join(self.ins_list[:3]) + "\t" + "\t".join([new_frag, self.ins_list[4], strand]) + "\t" + "\t".join(self.ins_list[6:])
            print(new_insertion, file=self.out_file)
    
    def single_te_diff_strand(self):
        '''对于第四列只有一种transposon，但是插入方向不同的insertion，进行拆分，修改第四列，并且调用single_te_same_strand方法'''
        te = list(self.ins_dic.keys())[0]
        self.ins_dic[te]["+"][0] = "(" + "_".join(self.ins_list[:3]) + "(" + self.ins_dic[te]["+"][0] #第四列信息的修改
        self.ins_dic[te]["-"][0] = "(" + "_".join(self.ins_list[:3]) + "(" + self.ins_dic[te]["-"][0]

        sense_dic = {te:{}}; anti_dic = {te:{}} #拆分正链和负链上的插入片段，并且各自构建修改后的"字典-字典-元组"嵌套结构，各自调用single_te_same_strand方法进行输出
        sense_dic[te]["+"] = self.ins_dic[te]["+"]; sense_dic[te]["-"] = []
        anti_dic[te]["-"] = self.ins_dic[te]["-"]; anti_dic[te]["+"] = []
        self.single_te_same_strand(sense_dic)
        self.single_te_same_strand(anti_dic)

    def single_te_mode(self):
        '''对于第四列中只有一种transposon的insertion，根据插入片段(第四列)的正负链情况，判断应该调用哪种方法'''
        te = list(self.ins_dic.keys())[0]
        if(self.ins_dic[te]["+"] and self.ins_dic[te]["-"]):
            self.single_te_diff_strand()
        else:
            self.single_te_same_strand(self.ins_dic)


def main(argv):
    in_file = ""
    out_file = ""
    try:
        #返回值opts是以元组为元素的列表，每个元组的形式为：(选项串, 附加参数)，如：('-i', '192.168.0.1')
        #而返回值args是个列表，其中的元素是那些不含'-'或'--'的参数。
        opts, args = getopt.getopt(argv, "hi:o:", ["help", "input=", "output="]) 
    except getopt.GetoptError:
        print('python divide_confusion_insertion.py -i <inputfile> -o <outputfile>')
        sys.exit(2)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print('python divide_confusion_insertion.py -i <inputfile> -o <outputfile>')
        elif opt in ("-i", "--input"):
            in_file = arg
        elif opt in ("-o", "--output"):
            out_file = arg

    if(in_file):
        ##首先对插入片段中，包含多种transposon fragment的"multi_fragment insertion"拆分成只包含一种transposon fragment的"single_fragment insertion"
        tmp_of = open("tmp1", "w")
        with open(in_file, "r") as in_f:
            for l in in_f:
                l=l.split()
                confusing_ins = Confusing_insertion(l, tmp_of)
                confusing_ins.mkdic()
                confusing_ins.multi_te_mode()
        tmp_of.close()

        ##对于只包含一种transposon fragment的"single_fragment insertion"，将位于不同链上的fragment拆分开来，并进行标记
        of = open(out_file, "w")
        with open("tmp1", "r") as in_f:
            for l in in_f:
                l=l.split()
                confusing_ins = Confusing_insertion(l, of)
                confusing_ins.mkdic()
                confusing_ins.single_te_mode()    
        of.close()

#argv[0]是脚本的名字，获取参数时，一般不考虑argv[0]
if __name__ == "__main__":
   main(sys.argv[1:])
