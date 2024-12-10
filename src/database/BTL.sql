DROP DATABASE  IF EXISTS ebook;
CREATE DATABASE ebook;
Use ebook;
CREATE TABLE User (
    UserID CHAR(5) PRIMARY KEY,	
    FullName VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    UserName VARCHAR(255) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    PhoneNumber CHAR(10) NOT NULL UNIQUE,
    Streak INT DEFAULT 0 CHECK(Streak >= 0),
    CONSTRAINT PhoneNumberSyntax CHECK ( REGEXP_LIKE ( PhoneNumber , '^[0-9]+$')),
    CONSTRAINT UserIDSyntax CHECK ( REGEXP_LIKE ( UserID ,'U-[0-9]{3}'))
    
);
DROP TABLE IF EXISTS TypePrice;
CREATE TABLE TypePrice (
    Type VARCHAR(255) PRIMARY KEY,
    Price DECIMAL(10, 2) NOT NULL
);
DROP TABLE IF EXISTS Transaction;
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
DROP TABLE IF EXISTS Membership;
CREATE TABLE Membership (
    UserID CHAR(5),
    Type VARCHAR(255) NOT NULL,
    ExpiredDay DATE DEFAULT (CURDATE() + INTERVAL 30 DAY),
    RemainingBooks INT DEFAULT 1 ,
    PRIMARY KEY (UserID,Type),
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (Type) REFERENCES TypePrice(Type)
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

CREATE TABLE Category
(
	CategoryID CHAR(5) PRIMARY KEY,
    Category_name VARCHAR(255) NOT NULL,
    CONSTRAINT CategoryIDSyntax CHECK ( REGEXP_LIKE ( CategoryID ,'C-[0-9]{3}'))
    
);

CREATE TABLE BookCat
(
	BookID CHAR(5),
    CategoryID CHAR(5),
    PRIMARY KEY (BookID, CategoryID),
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);
Use ebook;
DROP TABLE IF EXISTS Feedback;
CREATE TABLE Feedback (
    UserID CHAR(5),
    BookID CHAR(5),
    Comment TEXT,
    Rating INT DEFAULT 0 CHECK (Rating <= 5),
    Time TIMESTAMP NOT NULL DEFAULT current_timestamp,
    PRIMARY KEY( UserID, BookID),
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


Use ebook;
CREATE TABLE Access (
    UserID CHAR(5),
    BookID CHAR(5),
    AccessDate TIMESTAMP DEFAULT current_timestamp,
    PRIMARY KEY(UserID, BookID),
    FOREIGN KEY (UserID) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


CREATE TABLE IsFriendOf (
    UserID_1 CHAR(5),
    UserID_2 CHAR(5),
    Status VARCHAR(255) NOT NULL,
    PRIMARY KEY (UserID_1, UserID_2),
    FOREIGN KEY (UserID_1) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (UserID_2) REFERENCES User(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

DELIMITER $$

CREATE TRIGGER BeforeInsertIsFriendOf
BEFORE INSERT ON IsFriendOf
FOR EACH ROW
BEGIN
    IF NEW.UserID_1 = NEW.UserID_2 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'UserID_1 must be different from UserID_2';
    END IF;
END$$

DELIMITER ;


DELIMITER //
CREATE FUNCTION GetAverageRating(p_BookID CHAR(5)) 
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
    IN p_FullName VARCHAR(255),
	IN p_Email VARCHAR(255),
    IN p_UserName VARCHAR(255),
    IN p_Password VARCHAR(255),
    IN p_PhoneNumber CHAR(10)
)
BEGIN
If p_UserID is NULL or  p_FullName  is NULL or p_Email is NULL 
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
INSERT INTO User(UserID,FullName,Email, UserName, Password, PhoneNumber)
VALUEs (p_UserID,p_FullName,p_Email, p_UserName, p_Password, p_PhoneNumber);
END//


-- Delete User --
CREATE PROCEDURE DeleteUser(IN p_UserID CHAR(5))
BEGIN
IF p_UserID IS NULL THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error : Do not let UserID empty';
END IF;
IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: User not found';
END IF;
DELETE FROM User WHERE UserID = p_UserID;
SELECT 'Delete User successfully' AS Result;
END//
-- Update User --
CREATE PROCEDURE UpdateUser(
	IN p_UserID CHAR(5),
    IN p_FullName VARCHAR(255),
	IN p_Email VARCHAR(255),
    IN p_UserName VARCHAR(255),
    IN p_Password VARCHAR(255),
    IN p_PhoneNumber CHAR(10)
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
			FullName = coalesce(p_FullName, FullName),
			Email = coalesce(p_Email, Email),
			UserName = coalesce(p_UserName, UserName),
			Password = coalesce(p_Password, Password),
            PhoneNumber = coalesce(p_PhoneNumber, PhoneNumber)
		WHERE UserID = p_UserID;

		-- Return success message
		SELECT 'User updated successfully' AS Result;
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
    IN p_Type VARCHAR(255)
)
BEGIN
    -- Validate input parameters
    IF p_TransactionID IS NULL OR p_UserID IS NULL OR p_Type IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Required fields cannot be NULL';
    END IF;
	IF NOT ( REGEXP_LIKE ( p_TransactionID ,'T-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of TransactionID';
	END IF;
    IF NOT ( REGEXP_LIKE ( p_UserID ,'U-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    -- Ensure UserID exists in the User table
    IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: UserID does not exist';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM TypePrice WHERE Type = p_Type) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Type does not exist';
    END IF;

    -- Insert the transaction record
    INSERT INTO Transaction (TransactionID,UserID, Type)
    VALUES (p_TransactionID,p_UserID,p_Type);
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

DELIMITER //
Use ebook //

CREATE TRIGGER after_user_insert
AFTER INSERT ON User
FOR EACH ROW
BEGIN
    -- Insert default membership for new user, assuming "Silver" membership
    INSERT INTO Membership (UserID,Type)
    VALUES (NEW.UserID, 'Silver');
END //

DELIMITER ;

DELIMITER //
Use ebook //
CREATE TRIGGER update_info_after_transact
AFTER INSERT ON Transaction
FOR EACH ROW
BEGIN
	UPDATE Membership
    SET 
        
		Type = NEW.Type,
		ExpiredDay = (CURDATE() + INTERVAL 30 DAY)
    WHERE UserID = NEW.UserID;
END //
DELIMITER //

-- Procedure for Membership --
Use ebook;
DROP PROCEDURE IF EXISTS UpdateMembership;
DROP PROCEDURE IF EXISTS GetMembership;
DROP PROCEDURE IF EXISTS GetMembershipList;

DELIMITER //

CREATE PROCEDURE UpdateMembership
(
	IN p_UserID CHAR(5),
    IN p_Type VARCHAR(255),
    IN p_ExpiredDay DATE,
    IN p_RemainingBooks INT
)
BEGIN
	IF p_UserID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: UserID cannot be NULL';
    END IF;

    -- Check if the transaction exists
    IF NOT EXISTS (SELECT 1 FROM Membership WHERE UserID = p_UserID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Membership not found';
    END IF;

    -- Update the transaction record
    UPDATE Membership
    SET 
        Type = COALESCE(p_Type, Type),
        ExpiredDay = COALESCE(p_ExpiredDay, ExpiredDay),
        RemainingBooks = COALESCE(p_RemainingBooks, RemainingBooks)
    WHERE UserID = p_UserID;

    SELECT 'Membership updated successfully' AS Result;
END // 

CREATE PROCEDURE GetMembership (IN p_UserID CHAR(5))
BEGIN
	IF p_UserID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: UserID cannot be NULL';
    END IF;
	IF NOT ( REGEXP_LIKE ( p_UserID ,'U-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    -- Check if the book exists
    IF NOT EXISTS (SELECT 1 FROM Membership WHERE UserID = p_UserID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Membership not found';
    END IF;

    -- Retrieve the book
    SELECT *
    FROM Membership
    WHERE UserID = p_UserID;
END //


CREATE PROCEDURE GetMembershipList()
BEGIN 
	SELECT * 
    FROM Membership;
END //
DELIMITER ;

-- CRUD for Feedback --
Use ebook;
DROP PROCEDURE IF EXISTS InsertFeedback;
DROP PROCEDURE IF EXISTS DeleteFeedback;
DROP PROCEDURE IF EXISTS UpdateFeedback;
DROP PROCEDURE IF EXISTS GetFeedback;
DROP PROCEDURE IF EXISTS GetFeedbackList;
DELIMITER //
CREATE PROCEDURE InsertFeedback
(
	IN p_UserID CHAR(5),
    IN p_BookID CHAR(5),
    IN p_Comment TEXT,
    IN p_Rating DECIMAL(3, 2)
)
BEGIN 
	IF p_UserID is null or p_BookID is null or p_Rating is null THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Do not let any field empty';
    END IF;
    IF NOT ( REGEXP_LIKE ( p_UserID ,'U-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    IF NOT ( REGEXP_LIKE ( p_BookID ,'B-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of BookID';
	END IF;
    IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not exist';
	END IF;
    IF NOT EXISTS (SELECT 1 FROM Book WHERE BookID = p_BookID) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book not exist';
	END IF;
    IF p_Rating <= 0 OR p_Rating > 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Rating must be between 0 and 10';
    END IF;
    INSERT INTO Feedback (UserID, BookID, Comment, Rating)
    VALUES (p_UserID, p_BookID, coalesce(p_Comment), p_Rating);
END;
CREATE PROCEDURE GetFeedback
(
	IN p_UserID CHAR(5),
    IN p_BookID CHAR(5)
)
BEGIN 
	IF p_UserID is null or p_BookID is null THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Do not let any field empty';
    END IF;
    IF NOT ( REGEXP_LIKE ( p_UserID ,'U-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    IF NOT ( REGEXP_LIKE ( p_BookID ,'B-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of BookID';
	END IF;
    IF NOT EXISTS (SELECT 1 FROM Feedback WHERE UserID = p_UserID AND BookID = p_BookID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Feedback not found';
    END IF;
    SELECT * FROM Feedback
    WHERE UserID = p_UserID AND BookID = p_BookID;
    
END //
CREATE PROCEDURE DeleteFeedback(
    IN p_UserID CHAR(5),
    IN p_BookID CHAR(5)
)
BEGIN
    -- Validate inputs
    IF p_UserID IS NULL OR p_BookID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: UserID and BookID cannot be NULL';
    END IF;

    -- Check if the feedback exists
    IF NOT EXISTS (SELECT 1 FROM Feedback WHERE UserID = p_UserID AND BookID = p_BookID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Feedback not found';
    END IF;

    -- Delete the feedback record
    DELETE FROM Feedback
    WHERE UserID = p_UserID AND BookID = p_BookID;

    SELECT 'Feedback deleted successfully' AS Result;
END //
CREATE PROCEDURE UpdateFeedback(
    IN p_UserID CHAR(5),
    IN p_BookID CHAR(5),
    IN p_Comment TEXT,
    IN p_Rating DECIMAL(3, 2)
)
BEGIN
    -- Validate inputs
    IF p_UserID IS NULL OR p_BookID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: UserID and BookID cannot be NULL';
    END IF;

    -- Check if the feedback exists
    IF NOT EXISTS (SELECT 1 FROM Feedback WHERE UserID = p_UserID AND BookID = p_BookID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Feedback not found';
    END IF;

    -- Validate Rating
    IF p_Rating IS NOT NULL AND (p_Rating <= 0 OR p_Rating > 10) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Rating must be between 0 and 10';
    END IF;

    -- Update the feedback record
    UPDATE Feedback
    SET 
        Comment = COALESCE(p_Comment, Comment),
        Rating = COALESCE(p_Rating, Rating)
    WHERE UserID = p_UserID AND BookID = p_BookID;

    SELECT 'Feedback updated successfully' AS Result;
END //


DELIMITER ;


DELIMITER $$
DROP TRIGGER DecreaseRemainingBooks IF EXISTS;

CREATE TRIGGER DecreaseRemainingBooks
BEFORE INSERT ON Access
FOR EACH ROW
BEGIN
    DECLARE remaining INT;

    -- Get the remaining books for the user and membership type
    SELECT RemainingBooks INTO remaining
    FROM Membership
    WHERE UserID = NEW.UserID;

    -- Check if remaining books are greater than zero
    IF remaining > 0 THEN
        -- Decrease the remaining books
        UPDATE Membership
        SET RemainingBooks = RemainingBooks - 1
        WHERE UserID = NEW.UserID;
    ELSE
        -- Prevent insertion if no books remain
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No remaining books available for this membership.';
    END IF;
END$$

DELIMITER ;
Use ebook;
DROP PROCEDURE IF EXISTS AllPropertiesOfUserID;
DELIMITER //
Use ebook //
CREATE PROCEDURE AllPropertiesOfUserID (IN p_UserID CHAR(5))
BEGIN
	IF NOT ( REGEXP_LIKE ( p_UserID ,'U-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: UserID not found';
	END IF; 
    SELECT
		u.UserID,	
		u.FullName,
		u.Email,
		u.UserName,
		u.Password,
		u.PhoneNumber,
        u.Streak,
        t.TransactionID,
		t.TransactionDate,
        m.Type,
		m.ExpiredDay,
		m.RemainingBooks
	FROM 
		User u
	LEFT JOIN
		Transaction t on u.UserID = t.UserID
	LEFT JOIN 
		Membership m on u.UserID = m.UserID
	WHERE
		u.UserID = p_UserID;
END //
DELIMITER ;
Use ebook;
DROP PROCEDURE IF EXISTS getAllBookCategory;
DELIMITER //
Use ebook //
CREATE PROCEDURE getAllBookCategory (IN p_cat VARCHAR(255))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Category WHERE Category_name = p_cat) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Category not found';
    END IF;
	SELECT *
    FROM Book
    WHERE BookID IN ( SELECT BookID
					   FROM BookCat
                       WHERE CategoryID IN ( SELECT CategoryID
											 FROM Category
                                             WHERE Category_name = p_cat)) ;
END //
DELIMITER ;

Use ebook;
DROP PROCEDURE IF EXISTS InsertAccess;
DELIMITER //
CREATE PROCEDURE InsertAccess
(
	IN p_UserID CHAR(5),
    IN p_BookID CHAR(5)
)
BEGIN
	IF NOT ( REGEXP_LIKE ( p_UserID ,'U-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of UserID';
	END IF;
    IF NOT EXISTS (SELECT 1 FROM User WHERE UserID = p_UserID) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: UserID not found';
	END IF; 
    IF NOT ( REGEXP_LIKE ( p_BookID ,'B-[0-9]{3}')) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Wrong format of BookID';
	END IF;
    IF NOT EXISTS (SELECT 1 FROM Book WHERE BookID = p_BookID) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: BookID not found';
	END IF; 
    INSERT INTO Access(UserID, BookID)
    VALUES (p_UserID, p_BookID);
END //
DELIMITER ;


Use ebook;
DROP PROCEDURE IF EXISTS get_friend_by_UserID;
DELIMITER //
CREATE PROCEDURE get_friend_by_UserID(IN p_UserID VARCHAR(255))
BEGIN
	IF NOT EXISTS (SELECT * FROM IsFriendOf WHERE UserID_1 = p_UserID) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Not exist';
	END IF;
    SELECT * FROM IsFriendOf
    WHERE UserID_1 = p_UserID;
END //
DELIMITER ;

Use ebook;
DROP PROCEDURE IF EXISTS CheckLogin;
DELIMITER //


DELIMITER //

CREATE PROCEDURE CheckLogin(IN p_UserName VARCHAR(255), IN p_Password VARCHAR(255))
BEGIN
    DECLARE v_UserID CHAR(5);

    -- Attempt to find the user with the given username and password
    SELECT UserID INTO v_UserID
    FROM User
    WHERE UserName = p_UserName AND Password = p_Password;

    -- Return the UserID if found, otherwise return NULL
    IF v_UserID IS NOT NULL THEN
        SELECT v_UserID AS UserID;
    ELSE
        SELECT NULL AS UserID;
    END IF;
END //

DELIMITER ;


DELIMITER ;
