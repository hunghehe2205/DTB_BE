import mysql.connector
from mysql.connector import Error
from pydantic import EmailStr
from typing import Optional


class UserModel():
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

    def generate_user_id(self):
        connection = self.get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT MAX(UserID) FROM User;")
        result = cursor.fetchone()
        max_user_id = result[0]  # Fetch the current max UserID

        # Generate the next UserID
        if max_user_id is None:
            # If no UserID exists, start with 'U-001'
            next_user_id = "U-001"
        else:
            # Extract the numeric part, increment it, and format with leading zeros
            numeric_part = int(max_user_id.split('-')[1])
            next_user_id = f"U-{numeric_part + 1:03d}"

        cursor.close()
        connection.close()
        return next_user_id

    def create_user(self, fname: str, lname: str,
                    email: EmailStr, username: str, password: str,
                    phonenumber: str):

        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                get_user_id = self.generate_user_id()
                insert_query = "INSERT INTO User (UserID, FName, LName, Email, UserName, Password, PhoneNumber) VALUES (%s, %s, %s, %s, %s, %s, %s)"
                cursor.execute(insert_query, (get_user_id, fname,
                               lname, email, username, password, phonenumber))
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

    def update_user(self, user_id: str, fname: Optional[str] = None, lname: Optional[str] = None, email: Optional[EmailStr] = None,
                    username: Optional[str] = None, password: Optional[str] = None, phonenumber: Optional[str] = None):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc(
                    "UpdateUser", [user_id, fname, lname, email, username, password, phonenumber])
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

    def delete_user(self, user_id: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor()
                cursor.callproc("DeleteUser", [user_id])
                connection.commit()
                return {'message': 'Deleted successfully'}
            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}

    def get_user_by_id(self, user_id: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc("GetUser", [user_id])
                user_data = None
                for result in cursor.stored_results():
                    user_data = result.fetchone()

            # Check if user data was found
                if user_data:
                    return user_data
                else:
                    return {'error': 'User not found'}

            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}

    def get_user_list(self):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                # Execute a query to retrieve all users
                query = "SELECT * FROM User"
                cursor.execute(query)
                # Fetch all users
                user_list = cursor.fetchall()
                # Check if there are any users
                if user_list:
                    return user_list
                else:
                    return {'message': 'No users found'}

            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}
