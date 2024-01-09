---------------------------------------------------------------------------------
           /* Financial Transactions Analysis for Retail Banking*/
---------------------------------------------------------------------------------

   /* This project aims to analyze a dataset of financial transactions from 
   a retail bank. This project examines spending, product usage, and transaction 
   frequency across income groups. Key areas include monthly expenditure, product 
   preference, spending distribution by merchants, and transaction trends.*/

---------------------------------------------------------------------------------

                         /* Inspecting the Data */

USE prj1;
SELECT * FROM account_information$;
SELECT * FROM customer_demographics$;
SELECT * FROM product_usage$;
SELECT * FROM transaction_details$;

---------------------------------------------------------------------------------
                     /* Data Cleaning and Preprocessing */

/*Handle Missing Data:*/

--account_information TABLE
UPDATE account_information$ 
SET [Account Type] = 'Unknown'
WHERE [Account Type] IS NULL;

UPDATE account_information$
SET[Account Status] = 'Unknown'
WHERE [Account Status] IS NULL;
--

--customer_demographics$ TABLE
UPDATE customer_demographics$ --Filling missing Age values with an average
SET [Age] = (SELECT AVG([Age]) FROM customer_demographics$)
WHERE [Age] IS NULL;

UPDATE customer_demographics$
SET [Gender] = 'Unknown'
WHERE [Gender] IS NULL;

UPDATE customer_demographics$
SET [Income Group] = 'Unknown'
WHERE [Income Group] IS NULL;

UPDATE customer_demographics$
SET [Region] = 'Unknown'
WHERE [Region] IS NULL;
--

--product_usage$ TABLE
UPDATE product_usage$
SET [Interest Rate] = (SELECT AVG([Interest Rate]) FROM product_usage$)
WHERE [Interest Rate] IS NULL;
--

--transaction_details$ TABLE
UPDATE transaction_details$
SET [Merchant Category] = 'Unknown'
WHERE [Merchant Category] IS NULL;
--


--Correcting Data Formats




/* Dealing with Outliers and Invalid Data */

--account_information TABLE
SELECT *
FROM account_information$
WHERE [Account ID] < 0 OR [Customer ID] < 0;
--

--customer_demographics$ TABLE
UPDATE customer_demographics$
SET [Age] = (SELECT AVG([Age]) FROM customer_demographics$)
WHERE [Age] < 0;
--

--product_usage$ TABLE
UPDATE product_usage$
SET [Current Balance] = 0
WHERE [Current Balance] < 0;

UPDATE product_usage$
SET [Interest Rate] = (SELECT AVG([Interest Rate]) FROM product_usage$)
WHERE [Interest Rate] < 0 OR [Interest Rate] > 25; 
-- Assuming 25% as an upper limit for interest rate
--

--transaction_details$ TABLE
UPDATE transaction_details$
SET [Amount] = 0
WHERE [Amount] < 0;

UPDATE transaction_details$
SET [Amount] = (SELECT AVG([Amount]) FROM transaction_details$)
WHERE [Amount] > 100000;


/*Removing Duplicates*/

--account_information$ TABLE
DELETE a
FROM account_information$ a
JOIN (
    SELECT MIN([Account ID]) as id, [Customer ID]
    FROM account_information$
    GROUP BY [Customer ID]
    HAVING COUNT(*) > 1
) b ON a.[Account ID] = b.id
--

--customer_demographics$ TABLE
DELETE a
FROM customer_demographics$ a
JOIN (
    SELECT MIN([Customer ID]) as id
    FROM customer_demographics$
    GROUP BY [Customer ID]
    HAVING COUNT(*) > 1
) b ON a.[Customer ID] = b.id
--

--product_usage$ TABLE
DELETE a
FROM product_usage$ a
JOIN (
    SELECT MIN([Customer ID]) as id, [Product Type], [Product Start Date]
    FROM product_usage$
    GROUP BY [Customer ID], [Product Type], [Product Start Date]
    HAVING COUNT(*) > 1
) b ON a.[Customer ID] = b.id AND a.[Product Type] = b.[Product Type] 
AND a.[Product Start Date] = b.[Product Start Date]
--

-- transaction_details$ TABLE
DELETE a
FROM transaction_details$ a
JOIN (
    SELECT MIN([Transaction ID]) as id
    FROM transaction_details$
    GROUP BY [Transaction ID]
    HAVING COUNT(*) > 1
) b ON a.[Transaction ID] = b.id


---------------------------------------------------------------------------------
                             
		             /* Data Analysis */


-- Uncover Spending Patterns
USE prj1;
	
/*Monthly Expenditure by Income Group*/

SELECT 
    cd.[Income Group],
    YEAR(td.[Date of Transaction]) AS [Year],
    MONTH(td.[Date of Transaction]) AS [Month],
    SUM(td.[Amount]) AS Total_Spending
FROM 
    [transaction_details$] td
JOIN 
    [account_information$] ai ON td.[Account ID] = ai.[Account ID]
JOIN 
    [customer_demographics$] cd ON ai.[Customer ID] = cd.[Customer ID]
GROUP BY 
    cd.[Income Group],
    YEAR(td.[Date of Transaction]),
    MONTH(td.[Date of Transaction]);


---------------------------------------------------------------------------------

/*Comparison of Product Usage Across Income Groups*/

SELECT pu.[Product Type], cd.[Income Group], cd.[Region], COUNT(*) as UsageCount
FROM product_usage$ pu
JOIN customer_demographics$ cd ON pu.[Customer ID] = cd.[Customer ID]
GROUP BY pu.[Product Type], cd.[Income Group], cd.[Region];



---------------------------------------------------------------------------------

/*Spending Distribution by Income Group and Merchant Category*/ 

WITH TotalSpending AS (
    SELECT 
        cd.[Income Group],
        SUM(td.[Amount]) AS TotalAmount
    FROM 
        [transaction_details$] td
    INNER JOIN 
        [account_information$] ai ON td.[Account ID] = ai.[Account ID]
    INNER JOIN 
        [customer_demographics$] cd ON ai.[Customer ID] = cd.[Customer ID]
    GROUP BY 
        cd.[Income Group]
),

-- Calculate spending for each income group and merchant
GroupedSpending AS (
    SELECT 
        cd.[Income Group],
        td.[Merchant Category],
        SUM(td.[Amount]) AS AmountSpent
    FROM 
        [transaction_details$] td
    INNER JOIN 
        [account_information$] ai ON td.[Account ID] = ai.[Account ID]
    INNER JOIN 
        [customer_demographics$] cd ON ai.[Customer ID] = cd.[Customer ID]
    GROUP BY 
        cd.[Income Group], 
        td.[Merchant Category]
)

-- Calculate the percentage of total spending for each merchant within each income group
SELECT 
    gs.[Income Group],
    gs.[Merchant Category],
    gs.AmountSpent,
    (gs.AmountSpent / ts.TotalAmount) * 100 AS PercentageOfTotalSpending
FROM 
    GroupedSpending gs
INNER JOIN 
    TotalSpending ts ON gs.[Income Group] = ts.[Income Group]
ORDER BY 
    gs.[Income Group], 
    gs.[Merchant Category]


---------------------------------------------------------------------------------


/* Transaction Frequency by Income Group */
SELECT 
    cd.[Income Group],
    COUNT(td.[Transaction ID]) AS [Transaction Frequency]
FROM 
    [customer_demographics$] cd
JOIN 
    [account_information$] ai ON cd.[Customer ID] = ai.[Customer ID]
JOIN 
    [transaction_details$] td ON ai.[Account ID] = td.[Account ID]
GROUP BY 
    cd.[Income Group]
ORDER BY 
    cd.[Income Group];


---------------------------------------------------------------------------------

/*Transaction Type Frequency Analysis*/
WITH TransactionCounts AS (
    SELECT 
        cd.[Income Group],
        td.[Transaction Type],
        COUNT(td.[Transaction ID]) AS [Frequency]
    FROM 
        [customer_demographics$] cd
    JOIN 
        [account_information$] ai ON cd.[Customer ID] = ai.[Customer ID]
    JOIN 
        [transaction_details$] td ON ai.[Account ID] = td.[Account ID]
    GROUP BY 
        cd.[Income Group], 
        td.[Transaction Type]
),
RankedTransactions AS (
    SELECT 
        [Income Group],
        [Transaction Type],
        [Frequency],
        RANK() OVER (PARTITION BY [Income Group] ORDER BY [Frequency] DESC) as Rank
    FROM 
        TransactionCounts
)
SELECT 
    [Income Group],
    [Transaction Type],
    [Frequency]
FROM 
    RankedTransactions
WHERE 
    Rank = 1;


---------------------------------------------------------------------------------


--Customer Segments by Income and Region:
USE prj1;

SELECT [Income Group], [Region], COUNT(*) as CustomerCount
FROM customer_demographics$
GROUP BY [Income Group], [Region];




/*Loan and Credit Product Analysis*/
SELECT 
  [Product Type], 
  AVG([Current Balance]) as AverageBalance, 
  AVG([Interest Rate]) as AverageInterestRate
FROM product_usage$
WHERE [Product Type] IN ('Loan', 'Credit Card')
GROUP BY [Product Type];

/*Correlation Analysis*/
-- SQL to get average number of transactions per income group
 SELECT 
        cd_inner.[Income Group], 
        AVG(td_inner.TotalSpending) as AvgSpending
    FROM (
        SELECT 
            [Account ID], 
            SUM([Amount]) as TotalSpending
        FROM transaction_details$
        GROUP BY [Account ID]
    ) td_inner
    JOIN customer_demographics$ cd_inner ON td_inner.[Account ID] = cd_inner.[Customer ID]
    GROUP BY cd_inner.[Income Group]








  
























