# THIS SCRIPT READS THE CONTENTS OF TARGET_DEPENDENCIES.DB
# THIS IS WHERE FUNCTION DEFINITIONS FOR QUERYING
# DEPENDENCY INFO WILL GO, AND WHERE THEY WILL BE RUN FROM.

# FOR NOW, THIS SCRIPT JUST PRINTS THE KEY,VALUE PAIRS
# IN THE DATABASE AND PRINTS THE TOTAL NUMBER OF ROWS.

import SQLFUNCS as sql

db_name = "target_dependencies.db"
conn = sql.make_connection(db_name)
sql.get_all_tables(conn)
# sql.get_tds(conn)

all_keys = sql.get_keys(conn)
some_key = all_keys[10]
print "KEY:", some_key
sql.get_values(conn,some_key)
