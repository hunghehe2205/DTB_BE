import mysql.connector
from mysql.connector import Error
from typing import Optional
from datetime import date


class BookModel():
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

    def generate_book_id(self):
        connection = self.get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT MAX(BookID) FROM Book;")
        result = cursor.fetchone()
        max_book_id = result[0]  # Fetch the current max UserID

        # Generate the next UserID
        if max_book_id is None:
            # If no UserID exists, start with 'U-001'
            next_book_id = "B-001"
        else:
            # Extract the numeric part, increment it, and format with leading zeros
            numeric_part = int(max_book_id.split('-')[1])
            next_book_id = f"B-{numeric_part + 1:03d}"

        cursor.close()
        connection.close()
        return next_book_id

    def create_book(self, title: str, author: str, publication_date: date, release_date: date):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                get_book_id = self.generate_book_id()
                insert_query = "INSERT INTO Book (BookID, Title, Author, PublicationDate, ReleaseDate) VALUES (%s, %s, %s, %s, %s)"
                cursor.execute(insert_query, (get_book_id, title,
                               author, publication_date, release_date))
                connection.commit()
                return {'message': 'Adding book successfully'}
            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}

    def update_book_by_id(self, book_id: str, title: Optional[str] = None, author: Optional[str] = None, publication_date: Optional[date] = None,
                          rating: Optional[float] = None, release_date: Optional[date] = None):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc(
                    "UpdateBook", [book_id, title, author,
                                   publication_date, rating, release_date]
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

    def delete_book(self, book_id: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor()
                cursor.callproc("DeleteBook", [book_id])
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

    def get_book_by_id(self, book_id: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc("GetBook", [book_id])
                book_data = None
                for result in cursor.stored_results():
                    book_data = result.fetchone()

            # Check if user data was found
                if book_data:
                    return book_data
                else:
                    return {'error': 'Book not found'}

            except Error as e:
                result = {'error': f'[{e.msg}]'}
                connection.rollback()
                return result
            finally:
                cursor.close()
                connection.close()
        return {'error': 'Failed to connect to the database'}

    def get_book_list(self):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                # Execute a query to retrieve all users
                query = "SELECT * FROM Book"
                cursor.execute(query)
                # Fetch all users
                book_list = cursor.fetchall()
                # Check if there are any users
                if book_list:
                    return book_list
                elif book_list == {}:
                    return {'message': 'No book found'}

            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}

    def get_book_by_cat(self, category: str):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                cursor.callproc("getAllBookCategory", [category])
                book_list = []
                for result in cursor.stored_results():
                    book_list = result.fetchall()
                return book_list
            except Error as e:
                result = {'error': f'MySQL Error: [{e.msg}]'}
                connection.rollback()
                return result

            finally:
                if cursor:
                    cursor.close()
                connection.close()

        return {'error': 'Failed to connect to the database'}
