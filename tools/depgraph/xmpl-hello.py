import SQLFUNCS as sql
import sys
import os

db_name = "target_dependencies.db"
conn = sql.make_connection(db_name)
key = u'./x86_64/sbin/examples/xmpl-hello'

print ""
print ""
print "executable:",key
print ""
deps = sql.get_values(conn,key)
print "dependencies:",deps
print "------------"
key = deps[1]
print "next key",key
print ""
deps = sql.get_values(conn,key)
print "dependencies",deps
print ""
print "This includes:"
hello_o = deps[0]
errno_o = deps[1]
lib_bfish_a = deps[5]
lib_newlib_a = deps[8]
print "      hello.o  ",hello_o
print "      errno.o  ",errno_o
print "      lib_bfish_a  ",lib_bfish_a
print "      lib_newlib_a  ",lib_newlib_a
print "-----------------------"
key = hello_o
deps = sql.get_values(conn,key)
print "deps of hello.o are:"
print deps

