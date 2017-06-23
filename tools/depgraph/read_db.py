# THIS SCRIPT READS THE CONTENTS OF TARGET_DEPENDENCIES.DB

# IMPORTANT: before running this script, make sure that
# target_dependencies.db reflects up-to-date information.
# This script does not change anything in the database,
# so it is okay to run it several times, change filters,
# etc...

# Note that if parse_Markfile.py is run several times
# without rm'ing target_dependencies.db, problems may occur.

import SQLFUNCS as sql
import sys
import os
db_name = "target_dependencies.db"
conn = sql.make_connection(db_name)
sql.get_all_tables(conn)
all_keys = sql.get_keys(conn)
some_key = all_keys[10]
ret = sql.get_dependency_chain(conn,some_key)
ret = sql.filter_keep_extensions(ret,['.c','.h','.if'])
ret = sql.filter_exclude_substrings(ret,['../lib/','../if/'])
print "key is", some_key
print "result are:"
for r in ret:
    print r
