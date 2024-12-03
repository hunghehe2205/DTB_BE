DROP DATABASE  IF EXISTS ebook;
CREATE DATABASE ebook;
Use ebook;
CREATE TABLE User (
    UserID CHAR(5) PRIMARY KEY,
    FName VARCHAR(255) NOT NULL,
    LName VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    UserName VARCHAR(255) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    PhoneNumber CHAR(10) NOT NULL UNIQUE,
    Streak INT DEFAULT 0 CHECK(Streak >= 0),
    CONSTRAINT PhoneNumberSyntax CHECK ( REGEXP_LIKE ( PhoneNumber , '^[0-9]+$')),
    CONSTRAINT UserIDSyntax CHECK ( REGEXP_LIKE ( UserID ,'U-[0-9]{3}'))
    
);

CREATE TABLE Membership (
    UserID CHAR(5),
    Type VARCHAR(255) NOT NULL,
    ExpiredDay DATE NOT NULL ,
    RemainingBooks INT NOT NULL ,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE TypePrice(
	Type VARCHAR(255) PRIMARY KEY,
    Price DECIMAL NOT NULL
);


CREATE TABLE Transaction (
    TransactionID Char(5) PRIMARY KEY,
    UserID Char(5),
    TransactionDate TIMESTAMP DEFAULT current_timestamp,
    Type VARCHAR(255),
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (Type) REFERENCES TypePrice(Type),
    CONSTRAINT TransactIDSyntax CHECK ( REGEXP_LIKE ( TransactionID , 'T-[0-9]{3}'))
);

CREATE TABLE Book (
    BookID CHAR(5) PRIMARY KEY,
    Title VARCHAR(255) NOT NULL UNIQUE,
    Author VARCHAR(255) NOT NULL,
    PublicationDate DATE NOT NULL,
    Rating DECIMAL(3, 2) DEFAULT 0,
    ReleaseDate DATE NOT NULL,
    CONSTRAINT BookIDSyntax CHECK ( REGEXP_LIKE ( BookID ,'B-[0-9]{3}'))
);
/*
CREATE TABLE Access (
    UserID CHAR(5),
    BookID INT,
    AccessDate DATE,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);
*/
/*
CREATE TABLE Feedback (
    UserID CHAR(5),
    BookID INT,
    Comment TEXT,
    Rating DECIMAL(3, 2) DEFAULT 0 CHECK (Rating <= 10),
    Time TIMESTAMP NOT NULL,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE Friend (
    UserID CHAR(5),
    FriendUserID CHAR(5),
    Status VARCHAR(255) NOT NULL,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (FriendUserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


*/

DELIMITER //
CREATE FUNCTION GetAverageRating(bookID INT) 
RETURNS DECIMAL(3, 2)
DETERMINISTIC
BEGIN
    DECLARE avgRating DECIMAL(3, 2);
    
    SELECT AVG(Rating) INTO avgRating
    FROM Feedback
    WHERE BookID = bookID;
    
    RETURN COALESCE(avgRating, 0.00);
END//

-- CRUD for User --
Use ebook;
DROP PROCEDURE IF EXISTS InsertUser;
DROP PROCEDURE IF EXISTS DeleteUser;
DROP PROCEDURE IF EXISTS UpdateUser;
DROP PROCEDURE IF EXISTS GetUser;
DROP PROCEDURE IF EXISTS GetUserList;
DELIMITER //
Use ebook //
-- Insert --
CREATE PROCEDURE InsertUser(
	IN p_UserID CHAR(5),
    IN p_FName VARCHAR(255),
    IN p_LName VARCHAR(255),
	IN p_Email VARCHAR(255),
    IN p_UserName VARCHAR(255),
    IN p_Password VARCHAR(255),
    IN p_PhoneNumber CHAR(10)
)
BEGIN
If p_UserID is NULL or p_FName is NULL or p_LName is NULL or p_Email is NULL 
or p_UserName is NULL or p_Password is NULL or p_PhoneNumber is NULL THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Error: Do not let any field empty';
END IF;
IF LOCATE('@', p_Email) = 0 OR LOCATE('.', p_Email) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Invalid Email';
END IF;
IF EXISTS (SELECT 1 FROM User WHERE Email = p_Email) THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Error: Email exists';
END IF;
IF EXISTS (SELECT 1 FROM User WHERE UserName = p_UserName) THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Error: Username exists';
END IF;
INSERT INTO User(UserID,FName,LName,Email, UserName, Password, PhoneNumber)
VALUEs (p_UserID, p_FName, p_LName,p_Email, p_UserName, p_Password, p_PhoneNumber);
END//


-- Delete User --
CREATE PROCEDURE DeleteUser(IN p_UserId CHAR(5))
BEGIN
IF p_UserID IS NULL THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error : Do not let UserID empty';
END IF;
IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: User not found';
END IF;
DELETE FROM User WHERE User_ID = p_UserID;
SELECT 'Delete User successfully' AS Result;
END//
-- Update User --
CREATE PROCEDURE UpdateUser(
	IN p_UserID CHAR(5),
    IN p_FName VARCHAR(255),
    IN p_LName VARCHAR(255),
	IN p_Email VARCHAR(255),
    IN p_UserName VARCHAR(255),
    IN p_Password VARCHAR(255),
    IN p_PhoneNumber CHAR(10),
    IN p_Streak INT
)
BEGIN
-- Check null --
	IF p_UserID is NULL then 
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Do not let UserID empty';
	END IF;
	-- Check exist UserID --
	IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: UserID not found';
	END IF;
	IF p_Email is NOT NULL then
		IF EXISTS (SELECT 1 FROM User WHERE Email = p_Email) THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Error: Email exists';
		END IF;
	END IF;
	IF p_UserName is NOT NULL THEN
		IF EXISTS (SELECT 1 FROM User WHERE UserName = p_UserName) THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Error: Username exists';
		END IF;
	END IF;
	UPDATE User
		SET 
			FName = coalesce(p_FName, FName),
            LName = coalesce(p_LName, LName),
			Email = coalesce(p_Email, Email),
			UserName = coalesce(p_UserName, UserName),
			Password = coalesce(p_Password, Password),
            PhoneNumber = coalesce(p_PhoneNumber, PhoneNumber),
			Streak = coalesce(p_Streak, Streak)
		WHERE UserID = p_UserID;

		-- Return success message
		SELECT 'Student updated successfully' AS Result;
END //

-- Get User --

CREATE PROCEDURE GetUser( IN p_UserID CHAR(5))
BEGIN
	IF p_UserID is NULL then 
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Do not let UserID empty';
	END IF;
    IF NOT ( REGEXP_LIKE ( p_UserID ,'U-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: UserID not found';
	END IF; 
    SELECT * FROM User WHERE UserID = p_UserID; 
END //

CREATE PROCEDURE GetUserList()
BEGIN
    -- Select all users from the User table --
    SELECT * 
    FROM User;
END //
DELIMITER ;

-- CRUD for Membership --
-- Need more discussion --

-- CRUD for Book --
Use ebook;
DROP PROCEDURE IF EXISTS InsertBook;
DROP PROCEDURE IF EXISTS DeleteBook;
DROP PROCEDURE IF EXISTS UpdateBook;
DROP PROCEDURE IF EXISTS GetBook;
DROP PROCEDURE IF EXISTS GetBookList;

DELIMITER //
Use ebook //

CREATE PROCEDURE InsertBook(
	IN p_BookID CHAR(5),
    IN p_Title VARCHAR(255),
    IN p_Author VARCHAR(255),
    IN p_PublicationDate DATE,
    IN p_Rating DECIMAL(3, 2),
    IN p_ReleaseDate DATE
)
BEGIN
    -- Validate input fields
    IF p_BookID IS NULL or p_Title IS NULL OR p_Author IS NULL OR p_PublicationDate IS NULL OR p_ReleaseDate IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Required fields cannot be NULL';
    END IF;

    -- Check if the title already exists
    IF EXISTS (SELECT 1 FROM Book WHERE Title = p_Title) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Book title already exists';
    END IF;

    -- Insert the book record
    INSERT INTO Book (BookID, Title, Author, PublicationDate, Rating, ReleaseDate)
    VALUES (p_BookID, p_Title, p_Author, p_PublicationDate, COALESCE(p_Rating, 0), p_ReleaseDate);
END //

CREATE PROCEDURE DeleteBook(
    IN p_BookID CHAR(5)
)
BEGIN
    -- Validate BookID
    IF p_BookID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: BookID cannot be NULL';
    END IF;
    IF NOT ( REGEXP_LIKE ( p_BookID ,'B-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of BookID';
	END IF;
    
	
    -- Check if the book exists
    IF NOT EXISTS (SELECT 1 FROM Book WHERE BookID = p_BookID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Book not found';
    END IF;

    -- Delete the book
    DELETE FROM Book
    WHERE BookID = p_BookID;

    SELECT 'Book deleted successfully' AS Result;
END //
CREATE PROCEDURE UpdateBook(
    IN p_BookID CHAR(5),
    IN p_Title VARCHAR(255),
    IN p_Author VARCHAR(255),
    IN p_PublicationDate DATE,
    IN p_Rating DECIMAL(3, 2),
    IN p_ReleaseDate DATE
)
BEGIN
    -- Validate BookID
    IF p_BookID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: BookID cannot be NULL';
    END IF;

    -- Check if the book exists
    IF NOT EXISTS (SELECT 1 FROM Book WHERE BookID = p_BookID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Book not found';
    END IF;

    -- Update the book record
    UPDATE Book
    SET 
        Title = COALESCE(p_Title, Title),
        Author = COALESCE(p_Author, Author),
        PublicationDate = COALESCE(p_PublicationDate, PublicationDate),
        Rating = COALESCE(p_Rating, Rating),
        ReleaseDate = COALESCE(p_ReleaseDate, ReleaseDate)
    WHERE BookID = p_BookID;

    SELECT 'Book updated successfully' AS Result;
END //

CREATE PROCEDURE GetBook(
    IN p_BookID CHAR(5)
)
BEGIN
    -- Validate BookID
    IF p_BookID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: BookID cannot be NULL';
    END IF;
	IF NOT ( REGEXP_LIKE ( p_BookID ,'B-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    -- Check if the book exists
    IF NOT EXISTS (SELECT 1 FROM Book WHERE BookID = p_BookID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Book not found';
    END IF;

    -- Retrieve the book
    SELECT *
    FROM Book
    WHERE BookID = p_BookID;
END //

CREATE PROCEDURE GetBookList()
BEGIN
    -- Retrieve all books
    SELECT *
    FROM Book;
END //
DELIMITER ;


-- CRUD for Transaction --
Use ebook;
DROP PROCEDURE IF EXISTS InsertTransaction;
DROP PROCEDURE IF EXISTS DeleteTransaction;
DROP PROCEDURE IF EXISTS UpdateTransaction;
DROP PROCEDURE IF EXISTS GetTransaction;
DROP PROCEDURE IF EXISTS GetTransactionList;

DELIMITER //
Use ebook //
CREATE PROCEDURE InsertTransaction(
	IN p_TransactionID CHAR(5),
    IN p_UserID CHAR(5),
    IN p_Type VARCHAR(255),
    IN p_TransactionDate TIMESTAMP
)
BEGIN
    -- Validate input parameters
    IF p_Transaction_ID IS NULL OR p_UserID IS NULL OR p_Type IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Required fields cannot be NULL';
    END IF;

    -- Ensure UserID exists in the User table
    IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: UserID does not exist';
    END IF;

    -- Insert the transaction record
    INSERT INTO Transaction (TransactionID,UserID, Type, TransactionDate)
    VALUES (p_TransactionID,p_UserID,p_Type, p_TransactionDate);
END //
CREATE PROCEDURE DeleteTransaction(
    IN p_TransactionID CHAR(5)
)
BEGIN
    -- Validate TransactionID
    IF p_TransactionID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: TransactionID cannot be NULL';
    END IF;

    -- Check if the transaction exists
    IF NOT EXISTS (SELECT 1 FROM Transaction WHERE TransactionID = p_TransactionID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Transaction not found';
    END IF;

    -- Delete the transaction record
    DELETE FROM Transaction
    WHERE TransactionID = p_TransactionID;

    SELECT 'Transaction deleted successfully' AS Result;
END //

CREATE PROCEDURE UpdateTransaction(
    IN p_TransactionID CHAR(5),
    IN p_UserID CHAR(5),
    IN p_Type VARCHAR(255),
    IN p_TransactionDate TIMESTAMP
)
BEGIN
    -- Validate TransactionID
    IF p_TransactionID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: TransactionID cannot be NULL';
    END IF;

    -- Check if the transaction exists
    IF NOT EXISTS (SELECT 1 FROM Transaction WHERE TransactionID = p_TransactionID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Transaction not found';
    END IF;

    -- Update the transaction record
    UPDATE Transaction
    SET 
        UserID = COALESCE(p_UserID, UserID),
        Price = COALESCE(p_Price, Price),
        TransactionDate = COALESCE(p_TransactionDate, TransactionDate)
    WHERE TransactionID = p_TransactionID;

    SELECT 'Transaction updated successfully' AS Result;
END //

CREATE PROCEDURE GetTransaction(
    IN p_TransactionID CHAR(5)
)
BEGIN
    -- Validate TransactionID
    IF p_TransactionID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: TransactionID cannot be NULL';
    END IF;

    -- Check if the transaction exists
    IF NOT EXISTS (SELECT 1 FROM Transaction WHERE TransactionID = p_TransactionID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Transaction not found';
    END IF;

    -- Retrieve the transaction
    SELECT *
    FROM Transaction
    WHERE TransactionID = p_TransactionID;
END //

CREATE PROCEDURE GetTransactionList()
BEGIN
    -- Retrieve all transactions
    SELECT *
    FROM Transaction;
END //
DELIMITER ;






