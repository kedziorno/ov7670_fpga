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

#print(sys.argv[0])
#print("Hello ",sys.argv[1],", welcome!")

script = sys.argv[0]
directory = sys.argv[1]
file = sys.argv[2]

files = []

#print (sorted(os.listdir(sys.argv[1])))

# https://stackoverflow.com/a/168580
def file_sort(directory,file):
	currentmin = 0
	file_list = []
	#for fn in os.listdir(directory):
	#	if fn.endswith('.vcd'):
	#		file_list.append(fn)
	#		file_list.sort(key=lambda s: os.path.getctime(os.path.join(directory,fn)))
	a = [s for s in os.listdir(directory) if os.path.isfile(os.path.join(directory, s)) and s.startswith(file) and s.endswith('.vcd')]
	a.sort(key=lambda s: os.path.getmtime(os.path.join(directory, s)))
	return a
#	for i in os.listdir(directory):
#		a = os.stat(os.path.join(directory,i))
#		if a.st_ctime > currentmin:
#			currentmin = a.st_ctime
#			file_list.append([i,time.ctime(a.st_ctime),time.ctime(a.st_atime)])
#		else:
#			file_list.insert(0,[i,time.ctime(a.st_ctime),time.ctime(a.st_atime)])
#	return file_list
	#print (file_list)
	#return file_list

file_list = file_sort(directory,file)
#print (file_list)
#for item in file_list:
#	line = "ctime: {:<20} | name: {:>20}".format(item[0],item[1])
#	print(line)

#for fn in os.listdir(directory):
#	if fn.endswith('.vcd'):
#		files.append(fn)

#print (sorted(files))

#exit (1)

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
			#print (token)
			index_ct = index_ct + 1
	num_ct.insert(num_ct_index,index_ct)
	index_ct = 0
	num_ct_index = num_ct_index + 1

num_ct_index = 0
index_ct = 0

print (num_ct)

#exit (1)

#list_tokens.append()
#opened_files.append(f)

for fl in file_list:
	f = open(fl,"rb")
	list_tokens.append(tokenize(f))
	opened_files.append(f)

t_date = next(list_tokens[0])
t_version = next(list_tokens[0])
t_timescale = next(list_tokens[0])
t_module = next(list_tokens[0])

#print ("tokenssssssssssssssssssssssssss "+str(len(list_tokens[0])))

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
		#print (token)
		while 1:
			#try:
			#	pass
			#except StopIteration:
			#	break
			#else:
			if index == num_ct[num_ct_index]:
				index = 0
				break
			print (token)
			if (token.kind is TokenKind.DATE or token.kind is TokenKind.VERSION or token.kind is TokenKind.TIMESCALE or token.kind is TokenKind.SCOPE) and get_header == 1:
				token = next(lt)
				continue
			if token.kind is TokenKind.VAR and get_header == 1:
				token = next(lt)
				continue
			#for token in lt:
			if token.kind is TokenKind.VAR and get_header == 0:
				#print (token.data)
				#v = Variable(ident=token.var.id_code,type='wire',size=1,init='X').format_value(VarType.parameter,True)
				v = ScalarVariable(ident=token.var.id_code,type='wire',size=1,init='X')
				#v1 = writer.register_var(scope=t_module.scope.ident,name=token.var.id_code,var_type='wire',size=1,init='X')
				writer.register_alias(scope=t_module.scope.ident,name=token.var.reference,var=v)
				#writer.change(v,0,'X')
				#writer.dump_on(i-1)
				#writer.dump_off(i)
				list1.append(token.var.id_code)
				list2.append(token.var.reference)
				list3.append(v)
				i = i + 1
				#list4.append(v1)
				#print ("--------------------header get")
				token = next(lt)
				continue
			if token.kind is TokenKind.UPSCOPE or token.kind is TokenKind.ENDDEFINITIONS:
				 token = next(lt)
				 continue
			if token.kind is TokenKind.CHANGE_TIME or TokenKind.CHANGE_SCALAR:
				if get_first == 0:
					if token.kind is TokenKind.CHANGE_TIME and token.data == 0:
						print ("first")
						get_first = 1
						prev_max = token.data
						#print (token)
						#print ("asdasd "+str(prev_max))
						token = next(lt)
						index = index + 1
						continue
						#print ("iiiiiii "+str(i))
					if token.kind is TokenKind.CHANGE_SCALAR and prev_max == 0:
						#i = len(list1)-1
						#while i >= 0:
							#print ("iiiiiii "+str(i))
							#print (token.data.id_code)
							#print (token.data.value)
						#print (token)
							#token = next(lt)
							#print ("oldmaxxxxxxxxxxxxxxxx "+str(max))
						for l in list3:
							#print ("identttttttttttttttttt "+l.ident)
							if l.ident == token.data.id_code:
								v = ScalarVariable(ident=token.data.id_code,type='wire',size='1',init=token.data.value)
								writer.change(l,0,v)
							#i = i - 1
						token = next(lt)
						get_first = 1
						continue
				else:
					if token.kind is TokenKind.CHANGE_TIME and prev_max == 0:
						#print (token)
						if token.data + oldmax > max:
							max = token.data + oldmax 
						#v = Variable(ident=str(token.data),type='timestamp',size=8,init='0')
							#writer.dump_on(max)
							#writer.dump_off(max)
						#print ('#'+str(token.data))
						#	max1=0
						token = next(lt)
						index = index + 1
						continue 
					if token.kind is TokenKind.CHANGE_SCALAR and prev_max == 0:
						#print (token)
						#real_var = writer.register_var('', 'x', 'real', init=1.23)
						#print (max)
						#print (token.data)
						#v1 = writer.register_alias(token.data,token.data.id_code,'integer',8)
						#v1 = writer.register_alias(scope='asd',name=token.data.id_code,var='string')
						for l in list3:
							#print (l.ident)
							if l.ident == token.data.id_code:
								v = ScalarVariable(ident=token.data.id_code,type='wire',size='1',init=token.data.value)
								if get_header == 0:
									writer.dump_on(max)
								else:
									writer.dump_on(max+1)
								#print ("bbb " + str(max))
								#print (v.ident)
								#print (v.value)
								if get_header == 0:
									writer.change(l,max,v.value)
								else:
									writer.change(l,max+1,v.value)
								max1 = max1 + 1
								#writer.dump_on(max)
						token = next(lt)
						#print ("indexxxxxxxxxxxxxxxxxxxxx "+str(index))
						#if index == 8000:
						#	break
						#	index = 0
						#else:
						#	continue
					#writer.change(v,max,v.value)
					#max1 = max1 + 1
		num_ct_index = num_ct_index + 1
		print ("max "+str(max))
		print ("oldmax "+str(oldmax))
		print ("indexxxxxxxxxxxxxxxxxxxxx "+str(index))	
		
		get_header = 1
		get_first = 0
		oldmax = max
		#print ("max "+str(max))
		#print ("oldmax "+str(oldmax))
		#print (list1)
		#print (list2)
		#print (list3)
		#print (list4)


w.close()

for of in opened_files:
	of.close()

#asd = t_module.scope
#sd = ScopeDecl(type_=asd.type_,ident=asd.ident)

#import io
#from vcd.reader import TokenKind, tokenize
#vcd = b"$date today $end $timescale 1 ns $end"
#tokens = tokenize(io.BytesIO(vcd))
#token = next(tokens)
#assert token.kind is TokenKind.DATE
#assert token.date == 'today'
#token = next(tokens)
#assert token.kind is TokenKind.TIMESCALE
#assert token.timescale.magnitude.value == 1
#assert token.timescale.unit.value == 'ns'

#import sys
#from vcd import VCDWriter
#with VCDWriter(sys.stdout, timescale='1 ns', date='today') as writer:
#    counter_var = writer.register_var('a.b.c', 'counter', 'integer', size=8)
#    real_var = writer.register_var('a.b.c', 'x', 'real', init=1.23)
#    for timestamp, value in enumerate(range(10, 20, 2)):
#        writer.change(counter_var, timestamp, value)
#    writer.change(real_var, 5, 3.21)

#for token in tokens:
	#if token.kind is TokenKind.CHANGE_TIME:
		#print (token.data)
		#counter_var = writer.register_var('a.b.c', 'counter', 'integer', size=8)
		#print (ScopeDecl(token,1))
		#writer.register_var(token.data,'integer',ScopeDecl(token,1))
#				writer.register_var(scope=t_module.scope.ident,name=token.var.reference,var_type='wire',size=1,init='X')
#				writer.register_var(scope=t_module.scope.ident,name=token.var.id_code,var_type='wire',size=1,init='X')
	#writer.register_var(t_module.scope.ident,'module','string')
#print (sd)
#		if token.kind is not TokenKind.UPSCOPE:
#print (t_module.kind)
#print (t_module.span)
#print (t_module.data)
#print (t_module.scope)

#token = next(tokens)
#print (token.kind)
#print (token.span)
#print (token.data)
#print (token.comment)
#print (token.date)
#print (token.scope)
#print (token.timescale)
#print (token.var)
#print (token.version)
#print (token.time_change)
#print (token.scalar_change)
#print (token.vector_change)
#print (token.real_change)
#print (token.string_change)

#print ("")
#token = next(tokens)
#print (token.kind)
#print (token.span)
#print (token.data)
#print (token.date)

#print ("")
#token = next(tokens)
#print (token.kind)
#print (token.span)
#print (token.data)
#print (token.version)

#print ("")
#token = next(tokens)
#print (token.kind)
#print (token.span)
#print (token.data)
#print (token.timescale)

#print ("")
#token = next(tokens)
#print (token.kind)
#print (token.span)
#print (token.data)
#print (token.scope)

