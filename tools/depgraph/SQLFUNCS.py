# THIS IS A LIBRARY OF SQLITE FUNCTIONS USED BY
# PARSE_MARKFILE.PY, READ_DB.PY, DB_TEST.PY

import Queue
import sqlite3
from sqlite3 import Error
import sys
import os



# Simple list processing functions for 
# reducing dependency output
def filter_keep_extensions(names,extensions):
    
    return [name for name in names if
      any(os.path.splitext(name)[1] == ext for ext in extensions)]

def filter_exclude_substrings(names,substrings):
    
    return [name for name in names 
        if not any(substr in name for substr in substrings)]


# Creates a database and closes the connection to it
def create_db(db_file):
    try:
        conn = sqlite3.connect(db_file)
        print "sqlite3 version",sqlite3.version
        print "created",db_file
    except Error as e:
        print(e)
    finally:
        conn.close()

# Connects to a database (or creates it)
# and returns the connection
def make_connection(db_file):
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except Error as e:
        print e
    return None

# Creates a table with format specified
# by the second argument. See example
# in db_test.py
def create_table(conn, create_table_sql):
    try:
        c = conn.cursor()
        c.execute(create_table_sql)
    except Error as e:
        print e

# Inserts a target,dependency (td) entry into
# a td-formatted table
def insert_td(conn, td):
    sql = ''' INSERT INTO tds(target,dependencies)                                VALUES(?,?) '''
    cur = conn.cursor()
    cur.execute(sql, td)
    return cur.lastrowid

# Selects all target,dependency pairs
# from a td-formatted table
def select_all_tds(conn):
    cur = conn.cursor()
    cur.execute("SELECT * FROM tds")
    rows = cur.fetchall()
    return rows

# returns keys from td table in database
def get_keys(conn):
    rows = select_all_tds(conn)
    return [tar for tar,deps in rows]

# gets value associated with key
# Assumes query on target dependency table
def get_values(conn,key):
    c = conn.cursor()
    q = 'SELECT dependencies FROM tds WHERE target = ?'
    r = (key,)
    c.execute(q,r)
    matches = c.fetchall()
   
    assert not len(matches) > 1

    if len(matches) < 1:
        return []
    else:
        """
        Annoying: In the database, a key is
        a string of the path of a target,
        and a value of a string of comma sep.
        dependency paths.

        Even though keys are unique, the query
        hands back a singleton list. It will never
        return more than one value. If matches
        is empty, this means that we are looking
        at a dependency-less source file.

        To make things worse, for this single
        match, the result is in the form of
        (value,).

        So if our query is target1, matches
        looks like [("dep1,dep2",)]

        - We grab the single item matches[0]
            ("dep1,dep2",)
        - We turn the tuple into a list
            ["dep1,dep2",]
        - We grab the first element
            "dep1,dep2"
        - We split on commas to get
            ["dep1","dep2"]
        """   
        result_tuple = matches[0]
        result_str = list(result_tuple)[0]
        unicode_list = result_str.split(',')
        return [uni.strip() for uni in unicode_list]

# Breadth-first search of dependency
# tree associated with key. Consider
# using filters on the output of this
# function to reduce to large amount of 
# files.
def get_dependency_chain(conn,key):
    
    visited = set([key])
    q = Queue.Queue()

    deps = get_values(conn,key)    
    for d in deps:
        q.put(d)
        
    while not q.empty():
        t = q.get(False)
        if t not in visited:
            visited.add(t)
            deps = get_values(conn,t)
            for d in deps:
                q.put(d)
        q.task_done()
   
    return list(visited)

# Inserts some sample tds. Used in db_test.py
def insert_sample_tds(c):
    td1 = ("target_friendship","dep_listening,dep_trust")
    td2 = ("target_music","dep_harmony,dep_timbre")
    insert_td(c, td1)
    insert_td(c, td2)

# Prints names of all tables associated with a database.
# Primarily used to confirm that td table was correctly
# added to the database
def get_all_tables(c):
    res = c.execute("SELECT name FROM sqlite_master                                      WHERE type='table';")
    print "tables:", [name[0] for name in res]
