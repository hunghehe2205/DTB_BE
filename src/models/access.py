import mysql.connector
from mysql.connector import Error
from typing import Optional
from datetime import date


class AccessModel():
    def __init__(self, db_config):
        self.db_config = db_config

    def get_db_connection(self):
        try:
            connection = mysql.connector.connect(**self.db_config)
            if connection.is_connected():
                return connection
        except Error as e:
            print(f"Error connecting to database: {e}")
        return None

    def insert_transaction(self, user_id: str, book_id: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc('InsertAccess', [user_id, book_id])
                connection.commit()
                return {'message': 'Adding Access successfully'}
            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}
