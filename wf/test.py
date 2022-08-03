import sys
from vcd import VCDWriter

import io
from vcd.reader import TokenKind, tokenize, ScopeDecl, ScopeType
from vcd.common import ScopeType
from vcd.writer import Variable
 
f = open("wf.1.vcd","rb")
w = open("aaaa.vcd","w");

tokens = tokenize(f)

t_date = next(tokens)
t_version = next(tokens)
t_timescale = next(tokens)
t_module = next(tokens)

max = 0

with VCDWriter(w, timescale=t_timescale.data, version=t_version.data, date=t_date.data) as writer:
	for token in tokens:
		if token.kind is TokenKind.VAR:
			v = Variable(ident=token.var.id_code,type='wire',size=1,init='X')
			writer.register_alias(t_module.scope.ident,token.var.reference,v)
		if token.kind is TokenKind.CHANGE_TIME:
			#print (token.data)
			if token.data > max:
				max = token.data
		if token.kind is TokenKind.CHANGE_SCALAR:
			v = Variable(ident=token.data,type='wire',size=1,init=token.data.value)
			writer.register_alias('aaa',token.data.id_code,v)
	print ("max "+str(max))
			
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

