import mysql.connector
from mysql.connector import Error
from datetime import date
from typing import Optional


class MembershipModel():
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

    def update_membership(self, user_id: str, type: Optional[str] = None, expired_day: Optional[date] = None,
                          remainning_books: Optional[int] = None):

        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc(
                    "UpdateMembership", [user_id, type,
                                         expired_day, remainning_books]
                )
                connection.commit()
                return {'message': 'Updated successfully'}
            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}

    def get_membership_by_user_id(self, user_id: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc("GetMembership", [user_id])
                membership_data = None
                for result in cursor.stored_results():
                    membership_data = result.fetchone()

            # Check if user data was found
                if membership_data:
                    return membership_data
                else:
                    return {'error': 'Membership not found'}

            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}

    def get_membership_list(self):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                # Execute a query to retrieve all users
                query = "SELECT * FROM Membership"
                cursor.execute(query)
                # Fetch all users
                user_list = cursor.fetchall()
                # Check if there are any users
                if user_list:
                    return user_list
                else:
                    return {'message': 'No membership found'}

            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}
