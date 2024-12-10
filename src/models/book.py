import mysql.connector
from mysql.connector import Error
from typing import Optional
from datetime import date
from enum import Enum
from typing import List


class Categories(str, Enum):
    C_001 = "Fiction"
    C_002 = "Science Fiction"
    C_003 = "Fantasy"
    C_004 = "Thriller"
    C_005 = "Mystery"
    C_006 = "Romance"
    C_007 = "Historical Fiction"
    C_008 = "Non-fiction"
    C_009 = "Biography"
    C_010 = "Self-help"
    C_011 = "Cookbooks"
    C_012 = "Children's Books"
    C_013 = "Young Adult"
    C_014 = "Graphic Novels"
    C_015 = "Literary Fiction"
    C_016 = "Classics"
    C_017 = "True Crime"
    C_018 = "Poetry"
    C_019 = "Health & Wellness"
    C_020 = "Business & Economics"
    C_021 = "Art & Photography"
    C_022 = "Mindfulness & Meditation"
    C_023 = "Politics & Government"
    C_024 = "Religion & Spirituality"
    C_025 = "Environmentalism"
    C_026 = "Memoir"


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

    def create_book(self, title: str, author: str, publication_date: date, release_date: date, categories: List[str]):
        connection = self.get_db_connection()
        if connection:
            try:
                cursor = connection.cursor(dictionary=True)
                # Generate BookID
                get_book_id = self.generate_book_id()

                # Insert the book into the Book table
                insert_query = """
                    INSERT INTO Book (BookID, Title, Author, PublicationDate, ReleaseDate) 
                    VALUES (%s, %s, %s, %s, %s)
                """
                cursor.execute(insert_query, (get_book_id, title,
                               author, publication_date, release_date))

                # Insert into BookCat table
                query = "INSERT INTO BookCat (BookID, CategoryID) VALUES (%s, %s)"
                for cat in categories:
                    try:
                        # Convert string to Enum and get the Enum name
                        # Convert string to Categories Enum
                        cat_enum = Categories(cat)
                        cat_id = cat_enum.name
                        # Get the Enum name, e.g., "C_001"
                        cat_id = cat_id.replace('_', '-')
                        cursor.execute(query, (get_book_id, cat_id))
                    except ValueError:
                        # Handle invalid category gracefully
                        return {'error': f'Invalid category: {cat}'}
                # Commit the transaction
                connection.commit()
                return {'message': 'Insert book success',
                        'BookID': get_book_id}
            except Error as e:
                # Handle and rollback on error
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
                query = '''
                        SELECT 
                            bc.BookID,
                            GROUP_CONCAT(c.Category_name) AS Categories
                        FROM 
                            BookCat bc
                        JOIN 
                            Category c
                        ON 
                            bc.CategoryID = c.CategoryID
                        WHERE 
                            BookID = %s;
                        '''
                cursor.execute(query, (book_id,))
                cate = cursor.fetchone()
            # Check if user data was found
                if book_data:
                    book_data['categories'] = cate['Categories']
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

    def get_enum_from_string(category_name: str) -> Categories:
        try:
            # Look for the category name in the Enum values
            return Categories(category_name)
        except ValueError:
            # Handle case where the string doesn't match any Enum value
            raise ValueError(f"'{category_name}' is not a valid category")
