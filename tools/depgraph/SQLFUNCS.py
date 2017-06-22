# THIS IS A LIBRARY OF SQLITE FUNCTIONS USED BY
# PARSE_MARKFILE.PY

import sqlite3
from sqlite3 import Error

def create_db(db_file):
    try:
        conn = sqlite3.connect(db_file)
        print "sqlite3 version",sqlite3.version
        print "created",db_file
    except Error as e:
        print(e)
    finally:
        conn.close()
  
def make_connection(db_file):
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except Error as e:
        print e
    return None
def create_table(conn, create_table_sql):
    try:
        c = conn.cursor()
        c.execute(create_table_sql)
    except Error as e:
        print e

def insert_td(conn, td):

    sql = ''' INSERT INTO tds(target,dependencies)                                VALUES(?,?) '''
    cur = conn.cursor()
    cur.execute(sql, td)
    return cur.lastrowid
    
def select_all_tds(conn):
    cur = conn.cursor()
    cur.execute("SELECT * FROM tds")
    rows = cur.fetchall()
    return rows
    
def get_tds(conn):
    rows = select_all_tds(conn)
    for _id,tar,deps in rows:
        print "target:",tar
        deps = deps.split(',')
        print "dependencies:",deps
        print ""
    print "num entries:",len(rows)


def get_keys(conn):
    rows = select_all_tds(conn)
    return [tar for _id,tar,deps in rows]

def get_values(conn,key):

    c = conn.cursor()
    q = 'SELECT dependencies FROM tds WHERE target = ?'
    r = (key,)
    
    c.execute(q,r)
    all_rows = c.fetchall()
    print ('matches:',all_rows)

def insert_sample_tds(c):
    td1 = ("target1","dep2,dep3")
    td2 = ("target2","dep10,dep11")
    insert_td(c, td1)
    insert_td(c, td2)
    
def get_all_tables(c):
    res = c.execute("SELECT name FROM sqlite_master                                      WHERE type='table';")
    print "tables:", [name[0] for name in res]
 
def create_db_make_tds_table(db_name):
    create_db(db_name)
    conn = make_connection(db_name)
    create_table(conn, sql_create_tds_table)
    conn.close()


database = "db_name3.db"
sql_create_tds_table = """ CREATE TABLE IF NOT EXISTS tds (
                           id integer PRIMARY KEY,
                           target text NOT NULL,
                           dependencies text                                           ); """
                           
