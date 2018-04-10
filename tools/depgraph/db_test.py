# Simple target/dependency databse test.
# The sample entrys are:
#       target (key): target_friendship
#       dependencies: dep_listening, dep_trust
#       target (key): target_music
#       dependencies: dep_harmony, dep_timbre

import SQLFUNCS as sql
import sys
import os

db_name = "test.db"
sql_create_tds_table = """ CREATE TABLE IF NOT EXISTS tds (
        target text PRIMARY KEY,
        dependencies text); """

sql.create_db(db_name)
conn = sql.make_connection(db_name)
sql.create_table(conn,sql_create_tds_table)
sql.get_all_tables(conn)
sql.insert_sample_tds(conn)
keys = sql.get_keys(conn)
print "KEYS ARE:"
for k in keys:
    print "  ",k
    print "   value:",sql.get_values(conn,k)
