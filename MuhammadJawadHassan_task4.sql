USE [CRA];
GO

-- 1. Add discount with a default value of 0.00.
ALTER TABLE dbo.Subscriber
ADD discount DECIMAL(3,2) NOT NULL
    CONSTRAINT DF_Subscriber_discount
    DEFAULT (0.00) WITH VALUES;
GO


-- 2. Add email, allowing NULL values.
ALTER TABLE dbo.Person
ADD email VARCHAR(50) NULL;
GO


-- 3. Create the Domain table.
CREATE TABLE dbo.[Domain]
(
    domainID INT IDENTITY(1,1) PRIMARY KEY,
    domainName VARCHAR(15)
);
GO


-- 4. Insert the required domains.
INSERT INTO dbo.[Domain] (domainName)
VALUES ('gmail.com'),
       ('yahoo.com'),
       ('hotmail.com'),
       ('eif.viko.lt');
GO


-- 5. Generate an email using a random domain for each person.
UPDATE p
SET email = LOWER(
    LTRIM(RTRIM(p.firstName)) + '.' +
    LTRIM(RTRIM(p.lastName)) + '@' +
    (
        SELECT TOP (1) d.domainName
        FROM dbo.[Domain] AS d
        ORDER BY CHECKSUM(NEWID(), p.personID, d.domainID)
    )
)
FROM dbo.Person AS p;
GO


-- 6. Create the MobilePhone table.
CREATE TABLE dbo.MobilePhone
(
    mobTelID INT IDENTITY(1,1) PRIMARY KEY,
    manufacturer VARCHAR(15),
    model VARCHAR(30),
    price FLOAT,
    monthlyPrice FLOAT
);
GO


-- 7. Add an optional mobile phone reference.
ALTER TABLE dbo.Subscriber
ADD mobTelID INT NULL;
GO


-- 8. Create the foreign key relationship.
ALTER TABLE dbo.Subscriber
ADD CONSTRAINT FK_Subscriber_MobilePhone
    FOREIGN KEY (mobTelID)
    REFERENCES dbo.MobilePhone (mobTelID);
GO


-- 9. Import the mobile phone data.
-- Change this path if you saved the file elsewhere.
BULK INSERT dbo.MobilePhone
FROM 'C:\SQLData\mobile-phones.txt'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO


-- 10. Assign a random phone only to subscribers
-- whose contractEndDate is NULL.
UPDATE s
SET mobTelID =
(
    SELECT TOP (1) m.mobTelID
    FROM dbo.MobilePhone AS m
    ORDER BY CHECKSUM(NEWID(), s.subscriberID, m.mobTelID)
)
FROM dbo.Subscriber AS s
WHERE s.contractEndDate IS NULL;
GO