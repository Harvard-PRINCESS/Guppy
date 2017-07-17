# THIS SCRIPT PARSES A MARKFILE AND CREATES
# A TARGET,DEPENDENCY (TD) SQLITE3 DATABASE
# CALLED TARGET_DEPENDENCIES.db

# VERY IMPORTANT! IF A TARGET_DEPENDENCY.DB ALREADY
# EXISTS, RM IT BEFORE RUNNING THIS SCRIPT! DUPLICATION
# PROBLEMS MAY OCCUR IF CARE IS NOT TAKEN TO DO THIS.

# Running the Hake build system generates both
# the Makefile and the Markfile (code in Hake/Main.hs).
# These two contain similiar information, but the 
# Markfile contains only build target paths and dependency 
# paths, without other compiler flag information. The
# Markfile is structured in a format that is
# assumed to hold by this script.

# If one has not run Hake again, there is no reason
# to run this script again. Retrieve information
# from the existing target_dependencies.db using
# scripts like read_db.py and db_test.py.

import sys
import SQLFUNCS as sql

def clean(s):
    s = s.strip("")
    s = s.strip("")
    return s

lines = None
CUR_LINE = 0
target_deps = {}

with open("Markfile", "r") as f:
    lines = f.readlines()
NUM_LINES = len(lines)


# The following could be done with one loop
# But is a little easier to read as two
# Will keep it this way for now.

# 1) Parse Markfile and create dictionary
while CUR_LINE < NUM_LINES-1:
    assert "OUTPUTS" in lines[CUR_LINE]
    # output target is key of database
    key = clean(lines[CUR_LINE+1])

    # deps and predeps joined as string for
    # databse value
    deps = clean(lines[CUR_LINE+4])
    predeps = clean(lines[CUR_LINE+7])
    val = filter(None,[deps,predeps])
    val = [item for segments in val 
                for item in segments.split()]

    target_deps[key] = val
    CUR_LINE += 9 # consequence of Markfile format


# 2) Create database
sql_create_tds_table = """ CREATE TABLE IF NOT EXISTS tds (
        target text PRIMARY KEY,
        dependencies text); """

db_name = "target_dependencies.db"
sql.create_db(db_name)
conn = sql.make_connection(db_name)
sql.create_table(conn,sql_create_tds_table)
sql.get_all_tables(conn)

for tar,deps in target_deps.iteritems():
    tar = tar.strip()
    deps = [d.strip() for d in deps]
    comma_sep_dep_string = ','.join(deps)
    tmp = (tar,comma_sep_dep_string)
    ret = sql.insert_td(conn,tmp)

conn.commit()
conn.close()
