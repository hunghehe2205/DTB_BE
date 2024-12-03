import mysql.connector
from mysql.connector import Error
from typing import Optional
from datetime import datetime


class TransactModel():
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

    def generate_transact_id(self):
        connection = self.get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT MAX(TransactionID) FROM Transaction;")
        result = cursor.fetchone()
        max_transact_id = result[0]  # Fetch the current max UserID

        # Generate the next UserID
        if max_transact_id is None:
            # If no UserID exists, start with 'U-001'
            max_transact_id = "T-001"
        else:
            # Extract the numeric part, increment it, and format with leading zeros
            numeric_part = int(max_transact_id.split('-')[1])
            max_transact_id = f"T-{numeric_part + 1:03d}"

        cursor.close()
        connection.close()
        return max_transact_id

    def create_transact(self, user_id: str, type: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                get_user_id = self.generate_transact_id()
                cursor.callproc('InsertTransaction',[get_user_id,user_id,type])
                connection.commit()
                return {'message': 'Registration successfully'}
            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}
    