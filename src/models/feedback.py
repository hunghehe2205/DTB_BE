import mysql.connector
from mysql.connector import Error
from typing import Optional
from datetime import datetime


class FeedbackModel():
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

    def create_feedback(self, user_id: str, book_id: str, comment: str, rating: float):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc('InsertFeedback', [
                                user_id, book_id, comment, rating])

                connection.commit()
                return {'message': 'Created successfully'}
            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}

    def get_feedback(self, book_id: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                query = 'SELECT * FROM Feedback WHERE BookID = %s'
                cursor.execute(query, (book_id,))
                feed_back = None
                feed_back = cursor.fetchall()
                connection.commit()
            # Check if user data was found
                if feed_back:
                    return feed_back
                else:
                    return {'error': 'Feedback not found'}

            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}
