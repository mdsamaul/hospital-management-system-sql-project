--Create Hospital database
CREATE DATABASE Hospital
ON PRIMARY(
	NAME='hms_data_file',
	FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\hms_data_file.mdf',
	SIZE=10MB,
	MAXSIZE=100MB,
	FILEGROWTH=10%
)
LOG ON(
	NAME='hms_log_file',
	FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\hms_log_file.ldf',
	SIZE=10MB,
	MAXSIZE=50MB,
	FILEGROWTH=10%
);
GO

--using Hospital database
USE Hospital;
GO

--Password validity
DROP FUNCTION ValidPassword
CREATE FUNCTION ValidPassword(@Password VARCHAR(255))
RETURNS INT
AS
BEGIN
	DECLARE @Result INT =1;

	IF @Password NOT LIKE '%[A-Z]%'
	SET @Result=101;

	IF @Password NOT LIKE '%[a-z]%'
	SET @Result=102;

	IF @Password NOT LIKE '%[0-9]%'
	SET @Result =103;

	IF @Password NOT LIKE '%[^A-Za-z0-9]%'
	SET @Result =104;

	IF LEN(@Password) < 6
	SET @Result=106;

	RETURN @Result;
END;
GO



/*
signup table
	SignUpID,
	UserName,
	Password,
	Salt,
	FirstName,
	LastName,
	Email,
	Phone,
	Address,
	Role,
	SignUpDate
*/

CREATE TABLE SignUp(
	SignUpID INT PRIMARY KEY IDENTITY(101,1) NOT NULL,
	UserName VARCHAR(255) NOT NULL UNIQUE,
	Password VARCHAR(255) NOT NULL,
	Salt VARCHAR(255) NOT NULL,
	FirstName VARCHAR(255) NOT NULL,
	LastName VARCHAR(255) NOT NULL,
	Email VARCHAR(255) NOT NULL UNIQUE,
	Phone VARCHAR(255),
	Address VARCHAR(255),
	Role VARCHAR(255) NOT NULL,
	SignUpDate DATETIME DEFAULT GETDATE()
);
GO
DROP PROCEDURE SingUpUser
--Sign Up Stored Procedure
CREATE PROCEDURE SingUpUser
@UserName VARCHAR(255),
@Password VARCHAR(255),
@FirstName VARCHAR(255),
@LastName VARCHAR(255),
@Email VARCHAR(255),
@Phone VARCHAR(20),
@Address VARCHAR(255),
@Role VARCHAR(50)
AS
BEGIN
	

	IF EXISTS ( SELECT 1 FROM SignUp WHERE UserName=@UserName)
	BEGIN
		RAISERROR('UserName already exists.', 16,1);
		RETURN;
	END

	IF EXISTS ( SELECT 1 FROM SignUp WHERE Email=@Email)
	BEGIN
		RAISERROR ('Email already exists.' , 16, 1);
		RETURN;
	END

	IF dbo.ValidPassword(@Password) = 101
    BEGIN
        RAISERROR('Password must contain at least one uppercase letter.', 16, 1);
        RETURN;
    END

	IF dbo.ValidPassword(@Password) = 102
    BEGIN
        RAISERROR('Password must contain at least one lowercase letter.', 16, 1);
        RETURN;
    END
	IF dbo.ValidPassword(@Password) = 103
    BEGIN
        RAISERROR('Password must contain at least one number.', 16, 1);
        RETURN;
    END
	IF dbo.ValidPassword(@Password) = 104
    BEGIN
        RAISERROR('Password must contain at least one special character.', 16, 1);
        RETURN;
    END
	IF dbo.ValidPassword(@Password) = 106
    BEGIN
        RAISERROR('Password must be at least 6 characters long.', 16, 1);
        RETURN;
    END


	DECLARE @Salt VARBINARY(16);
	DECLARE @PasswordHash VARBINARY(64);

	SET @Salt = CAST(CRYPT_GEN_RANDOM(16) AS VARBINARY(16));

	SET @PasswordHash =HASHBYTES('SHA2_256', @Password + CAST (@Salt AS VARCHAR(16)));

	INSERT INTO SignUp (UserName, Password, Salt, FirstName, LastName, Email, Phone, Address, Role, SignUpDate)
    VALUES (@UserName, @PasswordHash, @Salt, @FirstName, @LastName, @Email, @Phone, @Address, @Role, GETDATE());

PRINT 'User signed up successfully';
END;
GO

exec SingUpUser 'samaul23','@SA2SDF','md','samaul','sama1AulA2@gmail.com','098765434','jhenaidah','admin';
go
truncate table SignUp
select * from SignUp;
go
--sign in 

CREATE TABLE SignIn(
	SignInId INT PRIMARY KEY IDENTITY(101,1) NOT NULL,
	UserName VARCHAR(255) NOT NULL,
	SignInTime DATETIME DEFAULT GETDATE(),
	SignOutTime DATETIME NULL DEFAULT GETDATE(),
	FOREIGN KEY (UserName) REFERENCES SignUp(UserName)
);
GO

SELECT * FROM SignIn;

--Verify Login

CREATE PROCEDURE VerifyLogin
@UserName VARCHAR(255),
@Password VARCHAR(255)
AS
BEGIN 
	DECLARE @StoredPasswordHash VARCHAR(64);
	DECLARE @StoreSalt VARCHAR(16);
	DECLARE @PasswordHash VARCHAR(64);

	SELECT @StoredPasswordHash=Password , @StoreSalt=Salt
	FROM SignUp
	WHERE UserName=@UserName;

	 IF @StoreSalt IS NULL OR @StoredPasswordHash IS NULL
    BEGIN
        RAISERROR('Invalid Username or Password.', 16, 1);
        RETURN;
    END

	SET @PasswordHash = HASHBYTES('SHA2_256', @Password + CAST(@StoreSalt AS VARCHAR(16)));

	  --SET @PasswordHash = HASHBYTES('SHA2_256', @Password + CAST (@StoreSalt AS VARCHAR(16)));
	--SET @StoredPasswordHash = HASHBYTES('SHA2_256', @Password + CAST(@StoreSalt AS VARCHAR(64)));
	IF @PasswordHash = @StoredPasswordHash
	BEGIN
		INSERT INTO SignIn (UserName,SignInTime,SignOutTime)
		VALUES (@UserName, GETDATE(),NULL);
	SELECT 'Login Successful' AS Message;
	END
	ELSE 
		BEGIN
			SELECT 'Invalid username or password' AS Message;
		END
	END;
	go

EXEC VerifyLogin 'samaul','@Sam5Ul#';
go





--Role table
CREATE TABLE Roles
(
	RoleId INT IDENTITY(101,1) PRIMARY KEY NOT NULL,
	RoleName VARCHAR(20) NOT NULL
);
GO


--admin table
CREATE TABLE Admin
(
	AdminId pk,
	UserName,
	Password,
	FirstName,
	LastName,
	Email,
	Phone,
	RoleId fk,
	DepartmentId fk
);