import sys
from vcd import VCDWriter

import io
from vcd.reader import TokenKind, tokenize, ScopeDecl, ScopeType
from vcd.common import ScopeType
from vcd.writer import Variable,ScalarVariable
 
f = open("wf.1.vcd","rb")
w = open("aaaa.vcd","w");

tokens = tokenize(f)

t_date = next(tokens)
t_version = next(tokens)
t_timescale = next(tokens)
t_module = next(tokens)

max = 0
max1 = 0
i = 0
list1 = []
list2 = []
list3 = []

with VCDWriter(w, timescale=t_timescale.data, version=t_version.data, date=t_date.data) as writer:
	for token in tokens:
		if token.kind is TokenKind.VAR:
			v = Variable(ident=token.var.id_code,type='wire',size=1,init='X')
			v1 = writer.register_alias(scope=t_module.scope.ident,name=token.var.reference,var=v)
#			v1 = writer.register_var(scope=t_module.scope.ident,name=token.var.reference,var_type='wire',size=1,init='X')
			list1.append(token.var.id_code)
			list2.append(token.var.reference)
			list3.append(v1)
#			list3.append(v)
		if token.kind is TokenKind.CHANGE_TIME:
			if token.data > max:
				max = token.data
			v = ScalarVariable(ident=str(max),type='str',size=8,init='1111')
			writer.change(v,max,max)
			max1=0
		if token.kind is TokenKind.CHANGE_SCALAR:
			#real_var = writer.register_var('', 'x', 'real', init=1.23)
			#print (max)
			print (token.data)
			#v1 = writer.register_alias(token.data,token.data.id_code,'integer',8)
			#v1 = writer.register_alias(scope='asd',name=token.data.id_code,var='string')
			v = ScalarVariable(ident=token.data.id_code,type='int',size=max1,init=token.data.value)
			#print (v.ident)
			#print (v.value)
			writer.change(v,max,max1)
			max1 = max1 + 1
		#print (max1)

print ("max "+str(max))
print (list1)
print (list2)
print (list3)
			
f.close()
w.close()

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

