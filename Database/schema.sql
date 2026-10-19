-- The schema the reports above read, in the SAME corpus deliberately: a report's edge target must be
-- asserted against what the schema parser ACTUALLY emits rather than against a literal. v1.56.0 shipped
-- SSIS data edges spelled dbo.Orders against consumers that join on the bare name, and neither parser's
-- own fixture could catch it.

CREATE TABLE dbo.Customers (
    CustomerId INT IDENTITY NOT NULL,
    Name       NVARCHAR(200) NOT NULL,
    Region     NVARCHAR(50) NULL,
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerId)
);
GO

CREATE TABLE dbo.Orders (
    OrderId    INT IDENTITY NOT NULL,
    CustomerId INT NOT NULL,
    Total      DECIMAL(18,2) NOT NULL,
    Status     NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (OrderId)
);
GO

CREATE TABLE dbo.OrderLines (
    OrderLineId INT IDENTITY NOT NULL,
    OrderId     INT NOT NULL,
    Sku         NVARCHAR(40) NOT NULL,
    Amount      DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_OrderLines PRIMARY KEY (OrderLineId)
);
GO

-- The procedure a dataset is backed by. Its name must be spelled the way 351 emits a procedure type, or
-- the report-to-procedure hop resolves to nothing - and that hop is the ONLY route from a proc-backed
-- dataset to the data.
CREATE PROCEDURE dbo.usp_LoadOrders
    @Since DATETIME2
AS
BEGIN
    SELECT o.OrderId, o.Total
      FROM dbo.Orders o
     WHERE o.Status = 'Open';
END
GO
