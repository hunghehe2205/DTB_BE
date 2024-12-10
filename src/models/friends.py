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

    def delete_by_user_id(self, user_id1: str, user_id2: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                query = 'DELETE FROM IsFriendOf WHERE UserID_1 = %s AND UserID_2 = %s'
                cursor.execute(query, (user_id1, user_id2))
                return {'message': 'Deleted success'}
            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}

    def update(self, user_id1: str, user_id2: str, status: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc('UpdateFriendshipStatus',
                                (user_id1, user_id2, status))
                connection.commit()
                return {'message': 'Hello'}
            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}

    def send_friend_request(self, userid_1: str, userid_2: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                status = 'Pending'
                query = 'INSERT INTO IsFriendOf(UserID_1, UserID_2, Status) VALUES (%s, %s, %s)'
                cursor.execute(query, (userid_1, userid_2, status))
                connection.commit()
                return {'message': 'Request Sent'}
            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}
