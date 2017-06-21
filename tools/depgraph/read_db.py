import SQLFUNCS as sql


db_name = "target_dependencies.db"
conn = sql.make_connection(db_name)
sql.get_all_tables(conn)
sql.get_tds(conn)
