# Author   : ko, HomeDL
# Versions :
#   1.0 - File created
#   1.1 - improvments
#
# This script will concatenate/merge/stick VCD files generated from
# Xilinx ChipScope. Tested with ISE 14.7 version and Sigrok Pulseview and this
# use pyvcd library
#
# Usage "script [path/to/VCDs] [prefix_files_VCD]"
# Ex. calling "python3 vcd_tool.py . waveform" will generate aaaa.vcd file
#
# Next, signal names (as headers) must be copy to generated file between
#   $scope module [MODULE_NAME] $end
# and
#   $upscope $end
# tags, example from first vcd source file (waveform.1.vcd)
#
# TODO check counter between files
# PYVCD use objects (added to list3) where this list must be empty
# between change to next file. Without this, probe #0 for current file is not
# properly added. Without this transit between current probe end and
# begining next probe is mandacious.   

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
  try:
    for token in tokens:
      if token.kind is TokenKind.CHANGE_TIME:
        index_ct = index_ct + 1
  except:
    print ("except")
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
get_header = 0
prev_max = 0
index = 0

list1 = []
list2 = []
list3 = []
list4 = []

with VCDWriter(w, timescale=t_timescale.data, version=t_version.data, date=t_date.data) as writer:
  for lt in list_tokens:
    try:
      token = next(lt)
    except:
      print ("except2")
    print ("file : "+str(num_ct_index))
    while 1:
      #print (str(token))
      if (token.kind is TokenKind.DATE or token.kind is TokenKind.VERSION or token.kind is TokenKind.TIMESCALE or token.kind is TokenKind.SCOPE):
        #print ("1")
        try:
          token = next(lt)
          continue
        except StopIteration:
          index = 0
          list3.clear()
          break
      if token.kind is TokenKind.VAR:
        #print ("2")
        v = ScalarVariable(ident=token.var.id_code,type='wire',size=1,init='X')
        if get_header == 0:
          try:
            writer.register_alias(scope=t_module.scope.ident,name=token.var.reference,var=v)
          except:
            print ("except1")
        list1.append(token.var.id_code)
        list2.append(token.var.reference)
        list3.append(v)
        try:
          token = next(lt)
          continue
        except StopIteration:
          index = 0
          list3.clear()
          break
      if token.kind is TokenKind.UPSCOPE or token.kind is TokenKind.ENDDEFINITIONS:
        #print ("2")
        get_header = 1 #hack - next event
        try:
          token = next(lt)
          continue
        except StopIteration:
          index = 0
          list3.clear()
          break
      if token.kind is TokenKind.CHANGE_TIME and token.data == 0:
        #print ("3")
        prev_max = token.data
        index = index + 1
        try:
          token = next(lt)
          continue
        except StopIteration:
          index = 0
          list3.clear()
          break
      if token.kind is TokenKind.CHANGE_SCALAR and prev_max == 0:
        #print ("4")
        i = len(list3)-1
        while i >= 0:
          for l in list3:
            v = Variable(ident=token.data.id_code,type='wire',size='1',init=token.data.value)
            #print (str(v))
            if l.ident == token.data.id_code:
              if get_header == 1:
                writer.dump_on(oldmax)
              else:
                writer.dump_on(oldmax)
              if get_header == 1:
                writer.change(l,oldmax,v.value)
              else:
                writer.change(l,oldmax,v.value)
          prev_max = 1
          i = i - 1
          try:
            token = next(lt)
            continue
          except StopIteration:
            index = 0
            list3.clear()
            break
      if token.kind is TokenKind.CHANGE_TIME and prev_max == 1:
        #print ("5")
        if token.data + oldmax > max:
          max = token.data + oldmax
        index = index + 1
        try:
          token = next(lt)
          continue
        except StopIteration:
          index = 0
          list3.clear()
          break
      if token.kind is TokenKind.CHANGE_SCALAR and prev_max == 1:
        #print ("6")
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
        try:
          token = next(lt)
          continue
        except StopIteration:
          index = 0
          list3.clear()
          break
    num_ct_index = num_ct_index + 1
    oldmax = max + 1
  
w.close()

for of in opened_files:
  of.close()

