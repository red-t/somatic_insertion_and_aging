import sys, getopt

class Insertion():
    '''这是一个用于表示一行insertion的类，每一行包含一个reference merged insertion，以及在各样本中相应的insertion'''
    def __init__(self, ins_list):
        '''形参ins_list是一个包含多个insertion的列表'''
        self.ins_list = ins_list
        self.length = len(ins_list)
        self.acception = 0
    
    def filteration(self):
        '''根据每个insertion的插入片段长度、frequency、类型、support reads数目来进行筛选。
            只要这些insertion中有一个符合标准，便接受其它的insertion，否则过滤掉。'''
        acception = 0
        for i in range(1, self.length):
            if(self.ins_list[i] != "."):
                insertion =  self.ins_list[i].split(";")
                length = insertion[3].split(":"); te = length[0]; length = int(length[2]) - int(length[1])
                info = insertion[4].split(":"); freq = float(info[0]); type = info[1]; reads = float(info[2])
                if( length>=0 and freq>=0.2 and type=="1p1" and reads>=5):
                    if(te=="LINE1"):
                        if(length >= 500):
                            acception = 1
                            break
                        else:
                            next
                    else:
                        acception = 1
                        break
                else:
                    next
            else:
                next
        
        return acception
    
    def change_reference(self):
        '''根据最短的insertion长度(并非插入片段长度)来修改reference insertion。也就是选取最短的insertion作为reference。'''
        self.acception = self.filteration()
        if(self.acception == 1):
            length = [100000]
            for i in range(1, self.length):
                if(self.ins_list[i] == "."):
                    length.append(100000)
                else:
                    insertion =  self.ins_list[i].split(";")
                    length.append(int(insertion[2]) - int(insertion[1]))
            
            self.ins_list[0] = self.ins_list[length.index(min(length))]

def main(argv):
    in_file = ""
    out_file = ""
    try:
        #返回值opts是以元组为元素的列表，每个元组的形式为：(选项串, 附加参数)，如：('-i', '192.168.0.1')
        #而返回值args是个列表，其中的元素是那些不含'-'或'--'的参数。
        opts, args = getopt.getopt(argv, "hi:o:", ["help", "input=", "output="]) 
    except getopt.GetoptError:
        print('python filter_confident_insertion.py -i <inputfile> -o <outputfile>')
        sys.exit(2)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print('python filter_confident_insertion.py -i <inputfile> -o <outputfile>')
        elif opt in ("-i", "--input"):
            in_file = arg
        elif opt in ("-o", "--output"):
            out_file = arg
    
    if(in_file):
        of = open(out_file, "w")
        with open(in_file) as ins:
            for l in ins:
                l=l.split()
                insertion = Insertion(l)
                acception = insertion.filteration()
                if(acception == 1):
                    insertion.change_reference()
                    print("\t".join(insertion.ins_list), file=of)
    
        of.close()

#argv[0]是脚本的名字，获取参数时，一般不考虑argv[0]
if __name__ == "__main__":
   main(sys.argv[1:])


#nohup python ../../../../bin/filter_confident_insertion.py -i tmp -o UMB1465_combined_filterd_result &