# This simple script concatenate/merge/stick VCD files generated from Xilinx ChipScope
# Tested with ISE 14.7 and Pulseview and use pyvcd library
# usage "script [path/to/VCDs] [prefix_files_VCD]"

import io
import sys
import os
import time

from vcd import VCDWriter
from vcd.reader import TokenKind, tokenize, ScopeDecl, ScopeType
from vcd.common import ScopeType,VarType
from vcd.writer import Variable,ScalarVariable

script = sys.argv[0]
directory = sys.argv[1]
file = sys.argv[2]

files = []

# https://stackoverflow.com/a/168580
def file_sort(directory,file):
	currentmin = 0
	file_list = []
	a = [s for s in os.listdir(directory) if os.path.isfile(os.path.join(directory, s)) and s.startswith(file) and s.endswith('.vcd')]
	a.sort(key=lambda s: os.path.getmtime(os.path.join(directory, s)))
	return a

file_list = file_sort(directory,file)
print (file_list)
print ("files " + str(len(file_list)))

w = open("aaaa.vcd","w");

list_tokens = []
opened_files = []

num_ct = []
num_ct_index = 0
index_ct = 0
for fl in file_list:
	f = open(fl,"rb")
	tokens = tokenize(f)
	for token in tokens:
		if token.kind is TokenKind.CHANGE_TIME:
			index_ct = index_ct + 1
	print ("file nr "+str(num_ct_index)+" -> "+str(index_ct)+" probes")
	num_ct.insert(num_ct_index,index_ct)
	index_ct = 0
	num_ct_index = num_ct_index + 1

num_ct_index = 0
index_ct = 0

for fl in file_list:
	f = open(fl,"rb")
	list_tokens.append(tokenize(f))
	opened_files.append(f)

t_date = next(list_tokens[0])
t_version = next(list_tokens[0])
t_timescale = next(list_tokens[0])
t_module = next(list_tokens[0])

max = 0
oldmax = 0
max1 = 0
i = 1
get_header = 0
get_first = 0
prev_max = 0
index = 0

list1 = []
list2 = []
list3 = []
list4 = []

with VCDWriter(w, timescale=t_timescale.data, version=t_version.data, date=t_date.data) as writer:
	for lt in list_tokens:
		token = next(lt)
		print ("file : "+str(num_ct_index))
		while 1:
			if (token.kind is TokenKind.DATE or token.kind is TokenKind.VERSION or token.kind is TokenKind.TIMESCALE or token.kind is TokenKind.SCOPE):
				token = next(lt)
				continue
			if token.kind is TokenKind.VAR:
				v = ScalarVariable(ident=token.var.id_code,type='wire',size=1,init='X')
				if get_header == 0:
					writer.register_alias(scope=t_module.scope.ident,name=token.var.reference,var=v)
				list1.append(token.var.id_code)
				list2.append(token.var.reference)
				list3.append(v)
				token = next(lt)
				continue
			if token.kind is TokenKind.UPSCOPE or token.kind is TokenKind.ENDDEFINITIONS:
				get_header = 1 #hack - next event
				token = next(lt)
				continue
			if token.kind is TokenKind.CHANGE_TIME and token.data == 0:
				get_first = 1
				prev_max = token.data
				token = next(lt)
				index = index + 1
				continue
			if token.kind is TokenKind.CHANGE_SCALAR and prev_max == 0:
				i = len(list3)-1
				for l in list3:
					v = Variable(ident=token.data.id_code,type='wire',size='1',init=token.data.value)
					if l.ident == token.data.id_code:
						if get_header == 1:
							writer.dump_on(oldmax+1)
						else:
							writer.dump_on(oldmax)
						if get_header == 1:
							writer.change(l,oldmax+1,v.value)
						else:
							writer.change(l,oldmax,v.value)
						token = next(lt)
				get_first = 1
				prev_max = 1
				continue
			if token.kind is TokenKind.CHANGE_TIME and prev_max == 1:
				if token.data + oldmax > max:
					max = token.data + oldmax 
				token = next(lt)
				index = index + 1
				continue 
			if token.kind is TokenKind.CHANGE_SCALAR and prev_max == 1:
				for l in list3:
					if l.ident == token.data.id_code:
						v = ScalarVariable(ident=token.data.id_code,type='wire',size='1',init=token.data.value)
						if get_header == 1:
							writer.dump_on(max)
						else:
							writer.dump_on(max+1)
						if get_header == 1:
							writer.change(l,max,v.value)
						else:
							writer.change(l,max+1,v.value)
						max1 = max1 + 1
				if index == num_ct[num_ct_index]:
					index = 0
					list3.clear()
					break
				else:
					token = next(lt)
					continue
		
		num_ct_index = num_ct_index + 1
		
		get_first = 0
		oldmax = max

w.close()

for of in opened_files:
	of.close()

