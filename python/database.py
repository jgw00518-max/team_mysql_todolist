import os

import pymysql

def connect():
    return pymysql.connect(
        host='192.168.20.229',
        user='root',
        password='qwer1234',
        database='imagetodolist',
        charset='utf8',
        port=3307
    )
