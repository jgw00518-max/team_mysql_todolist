import os

import pymysql

def connect():
    return pymysql.connect(
        host='192.168.20.229',
        user='root',
        password=os.environ.get('MYSQL_PASSWORD', ''),
        database='imagetodolist',
        charset='utf8',
        port=3307
    )
