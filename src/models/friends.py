import mysql.connector
from mysql.connector import Error


class FriendModel():
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

    def get_friend_list_by_user_id(self, user_id_1: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc('get_friend_by_UserID', (user_id_1,))
                friend_list = []
                for result in cursor.stored_results():
                    friends = result.fetchall()  # Fetch all rows instead of one
                    friend_list.extend(friends)  # Add all rows to friend_list
                connection.commit()
                return friend_list
            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}
