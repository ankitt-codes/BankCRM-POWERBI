use bank_crm;
-- Altering the column names in Bank_Churn_ table for optimized query.
ALTER TABLE Bank_Churn_ 
CHANGE COLUMN Exited ExitID INT;
ALTER TABLE Bank_Churn_ 
CHANGE COLUMN ISActiveMember ActiveID INT;

-- Task-1. What is the distribution of account balances across different regions?

select ci.GeographyID, g.GeographyLocation, round(sum(b.Balance),2) as Account_Balances from geography_ g
join customerinfo_ ci on g.GeographyID=ci.GeographyID 
join bank_churn_ b on ci.CustomerID=b.CustomerID
group by g.GeographyID, g.GeographyLocation; 

-- Task-2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)

-- SET SQL_SAFE_UPDATES = 0;
--  UPDATE customerinfo_
--  SET BankDOJ = STR_TO_DATE(BankDOJ, '%d-%m-%Y')
--  WHERE STR_TO_DATE(BankDOJ, '%d-%m-%Y') IS NOT NULL;
--  alter table customerinfo_ modify BankDOJ date;
--  SET SQL_SAFE_UPDATES = 1;

select CustomerID, Surname, EstimatedSalary from customerinfo_
where extract(month from BankDOJ) in (10,11,12)
order by EstimatedSalary desc 
limit 5;

-- Task-3. Calculate the average number of products used by customers who have a credit card. (SQL)

select avg(NumOfProducts) as Average_Number_of_Products from bank_churn_ 
where Has_creditcard = 1;

-- Task-4. Determine the churn rate by gender for the most recent year in the dataset.

 WITH RecentYearCustomers AS (
    SELECT CustomerID, GenderID
    FROM CustomerInfo_
    WHERE YEAR(BankDOJ) = (
        SELECT MAX(YEAR(BankDOJ))
        FROM CustomerInfo_)
)
SELECT GenderID,ROUND(AVG(b.ExitID) * 100, 2) AS ChurnRatePercentage
FROM RecentYearCustomers c
JOIN Bank_Churn_ b ON c.CustomerID = b.CustomerID
GROUP BY c.GenderID;

-- Task-5. Compare the average credit score of customers who have exited and those who remain. (SQL)

select ExitID, round(avg(CreditScore),2) as Average_credit_score from bank_churn_
group by ExitID;

-- Task-6. Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)

WITH GenderSalary AS (
    -- Calculate the average estimated salary by gender
    SELECT GenderID, AVG(EstimatedSalary) AS AvgEstimatedSalary
    FROM CustomerInfo_
    GROUP BY GenderID
),
GenderActiveAccounts AS (
    -- Count the number of active accounts by gender
    SELECT ci.GenderID, COUNT(*) AS ActiveAccounts
    FROM CustomerInfo_ ci
    JOIN Bank_Churn_ bc ON ci.CustomerID = bc.CustomerID
    WHERE bc.ActiveID = 1
    GROUP BY ci.GenderID
)
-- Join the two CTEs to compare salary and active accounts by gender
SELECT gs.GenderID, round(gs.AvgEstimatedSalary,2), ga.ActiveAccounts
FROM GenderSalary gs
JOIN GenderActiveAccounts ga ON gs.GenderID = ga.GenderID
ORDER BY gs.AvgEstimatedSalary DESC;

-- Tasl-7. Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)

-- Credit score segments.
 SELECT CustomerID, CASE 
	WHEN CreditScore >= 800 THEN 'Excellent'
	WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good '
	WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
	WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair '
	ELSE 'Poor' END AS CreditScoreSegment
    FROM Bank_Churn_;
-- 
WITH CreditScoreSegments AS (
    -- Categorize customers based on their credit score into segments
    SELECT 
        CustomerID,
        CASE 
            WHEN CreditScore >= 800 THEN 'Excellent'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good '
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair '
            ELSE 'Poor'
        END AS CreditScoreSegment
    FROM Bank_Churn_
),

ExitRateBySegment AS (
    -- Calculate the exit rate by credit score segment
    SELECT 
        css.CreditScoreSegment,
        COUNT(bc.ExitID) AS TotalCustomers, SUM(bc.ExitID) AS ExitedCustomers,ROUND(AVG(bc.ExitID) * 100, 2) AS ExitRatePercentage
    FROM CreditScoreSegments css
    JOIN Bank_Churn_ bc ON css.CustomerID = bc.CustomerID
    GROUP BY css.CreditScoreSegment
)
-- Select the segment with the highest exit rate
SELECT CreditScoreSegment, TotalCustomers, ExitedCustomers, ExitRatePercentage
FROM ExitRateBySegment
ORDER BY ExitRatePercentage DESC
LIMIT 1;

-- Task-8. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)

WITH ActiveCustomersTenure AS (
    -- Select active customers with a tenure greater than 5 years
    SELECT ci.CustomerID, ci.GeographyID, bc.Tenure
    FROM CustomerInfo_ ci
    JOIN Bank_Churn_ bc ON ci.CustomerID = bc.CustomerID
    WHERE bc.ActiveID= 1 AND bc.Tenure > 5
)
-- Count the number of active customers per geographic region
SELECT act.GeographyID, g.GeographyLocation, COUNT(act.CustomerID) AS ActiveCustomersWithTenure
FROM ActiveCustomersTenure act 
join geography_ g on act.GeographyID=g.GeographyID
GROUP BY act.GeographyID, g.GeographyLocation
ORDER BY ActiveCustomersWithTenure DESC
LIMIT 1;

-- Task-9. What is the impact of having a credit card on customer churn, based on the available data?

WITH CreditCardChurn AS (
    -- Group customers by whether they have a credit card and calculate churn rate
    SELECT 
        CreditID,  -- 1 = Has Credit Card, 0 = No Credit Card
        COUNT(CustomerID) AS TotalCustomers, SUM(ExitID) AS ExitedCustomers, ROUND(AVG(ExitID) * 100, 2) AS ChurnRatePercentage
    FROM bank_churn_
    GROUP BY CreditID
)
-- Select and display churn data for customers with and without a credit card
SELECT CASE 
	WHEN CreditID = 1 THEN 'Has Credit Card' 
	ELSE 'No Credit Card' END AS CreditCardStatus,
    TotalCustomers, ExitedCustomers, ChurnRatePercentage
FROM CreditCardChurn;

-- Task-10. For customers who have exited, what is the most common number of products they have used?
SELECT NumOfProducts, COUNT(*) AS NumberOfExitedCustomers
FROM bank_churn_
WHERE ExitID = 1  -- Only consider customers who have exited
GROUP BY NumOfProducts
ORDER BY NumberOfExitedCustomers DESC
LIMIT 1;

-- Task-11. Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly).
 -- Prepare the data through SQL and then visualize it.
 
 -- Yearly trend of customer sign-ups
SELECT YEAR(BankDOJ) AS YearJoined, COUNT(CustomerID) AS CustomersJoined
FROM customerinfo_
GROUP BY YearJoined
ORDER BY YearJoined;
-- Monthly trend of customer sign-ups (ignores year, focuses on month across all years)
SELECT MONTHNAME(BankDOJ) AS MonthJoined, COUNT(CustomerID) AS CustomersJoined
FROM customerinfo_
GROUP BY MonthJoined
ORDER BY MonthJoined;


-- Task-12. Analyze the relationship between the number of products and the account balance for customers who have exited. 

SELECT NumOfProducts  , round(avg(Balance),2)as Avg_Balance 
FROM bank_churn_
WHERE ExitID = 1 
GROUP BY NumOfProducts;

-- Task-13. Identify any potential outliers in terms of balance among customers who have remained with the bank.

WITH BalanceStats AS (
    SELECT 
        AVG(Balance) AS MeanBalance,
        STDDEV(Balance) AS StdDevBalance
    FROM bank_churn_
    WHERE ExitID = 0
),
OutlierDetection AS (
    SELECT CustomerID, Balance, (Balance - MeanBalance) / StdDevBalance AS ZScore
    FROM bank_churn_, BalanceStats
    WHERE ExitID = 0
)
SELECT 
    CustomerID, 
    Balance, 
    ZScore
FROM 
    OutlierDetection
-- WHERE 
   --  ABS(ZScore) > 3;

-- Task-14. How many different tables are given in the dataset, out of these tables which table only consists of categorical variables?

-- Task-15. Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. 
-- Also, rank the gender according to the average value. (SQL)

WITH GenderIncome AS (
    SELECT c.GeographyID, c.GenderID,g.GenderCategory, AVG(c.EstimatedSalary) AS AvgIncome
    FROM customerinfo_ c 
    join gender_ g on c.GenderID=g.GenderID
    GROUP BY c.GeographyID, c.GenderID, g.GenderCategory
),
RankedGenderIncome AS (
    SELECT GeographyID, GenderID,GenderCategory, AvgIncome,
        RANK() OVER (PARTITION BY GeographyID ORDER BY AvgIncome DESC) AS IncomeRank
    FROM GenderIncome
)
SELECT GeographyID, GenderID,GenderCategory, AvgIncome, IncomeRank
FROM RankedGenderIncome
ORDER BY GeographyID, IncomeRank;

-- Task-16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

WITH AgeBracket AS (
    SELECT 
        CASE 
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '50+' 
        END AS AgeRange, Tenure
    FROM customerinfo_ AS CI
    JOIN bank_churn_ AS BC
    ON CI.CustomerID = BC.CustomerID
    WHERE BC.ExitID = 1
)
SELECT AgeRange, ROUND(AVG(Tenure),2) AS AvgTenure
FROM AgeBracket
GROUP BY AgeRange
ORDER BY AgeRange;

-- Task-17. Is there any direct correlation between salary and the balance of the customers? 
-- And is it different for people who have exited or not?
SELECT CORR(c.EstimatedSalary, b.Balance) AS correlation
FROM customerinfo_ c 
join bank_churn_ b on c.CustomerID=b.CustomerID;

-- Task-18. Rank each bucket of credit score as per the number of customers who have churned the bank.
WITH CreditScoreBuckets AS (
    SELECT 
        CASE 
            WHEN CreditScore BETWEEN 300 AND 500 THEN '300-500'
            WHEN CreditScore BETWEEN 501 AND 700 THEN '501-700'
            WHEN CreditScore BETWEEN 701 AND 850 THEN '701-850'
            ELSE 'Other' 
        END AS CreditScoreBucket,
        COUNT(CustomerID) AS ChurnedCount
    FROM bank_churn_
    WHERE ExitID = 1  -- Filter for customers who have churned
    GROUP BY CreditScoreBucket
),
RankedBuckets AS (
    SELECT CreditScoreBucket, ChurnedCount,
        RANK() OVER (ORDER BY ChurnedCount DESC) AS `Rank`
    FROM CreditScoreBuckets
)
SELECT CreditScoreBucket, ChurnedCount, `Rank`
FROM RankedBuckets;

-- Task-20. According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket.
WITH AgeBucketCreditCardCount AS (
    SELECT 
        CASE 
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '50+' 
        END AS AgeBucket,
        COUNT(CI.CustomerID) AS CreditCardCount
    FROM customerinfo_ AS CI
    JOIN bank_churn_ AS BC
    ON CI.CustomerID = BC.CustomerID
    WHERE BC.CreditID = 1  -- Filter for customers who have a credit card
    GROUP BY AgeBucket
),
AverageCreditCardCount AS (
    SELECT  AVG(CreditCardCount) AS AvgCreditCardCount
    FROM AgeBucketCreditCardCount
)
SELECT AgeBucket, CreditCardCount
FROM AgeBucketCreditCardCount,
    AverageCreditCardCount
WHERE CreditCardCount < AvgCreditCardCount;

-- Task-21.  Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
WITH ChurnedStats AS (
    SELECT 
        CI.GeographyID,
        COUNT(BC.CustomerID) AS ChurnedCount, 
        AVG(BC.Balance) AS AvgBalance
    FROM Bank_Churn_ AS BC
    JOIN CustomerInfo_ AS CI
    ON BC.CustomerID = CI.CustomerID
    WHERE BC.ExitID = 1  -- Filter for customers who have churned
    GROUP BY GeographyID
),
RankedLocations AS (
    SELECT 
        GeographyID,
        ChurnedCount,
        AvgBalance,
        RANK() OVER (ORDER BY ChurnedCount DESC) AS ChurnRank,
        RANK() OVER (ORDER BY AvgBalance DESC) AS BalanceRank
    FROM ChurnedStats
)
SELECT  GeographyID, ChurnedCount, AvgBalance, ChurnRank, BalanceRank
FROM RankedLocations
ORDER BY ChurnRank, BalanceRank;
    
-- Task-22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.

SELECT 
    CustomerID, Surname,
    CONCAT(CustomerID, '_', Surname) AS CustomerID_Surname
FROM customerinfo_;

-- Task-23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.

SELECT 
    BC.*, 
    (SELECT EC.ExitCategory 
     FROM exitcustomer_ AS EC 
     WHERE EC.ExitID = BC.ExitID) AS ExitCategory
FROM bank_churn_ AS BC;

-- Task-25. Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.

SELECT c.CustomerID, c.Surname, a.ActiveCategory
FROM customerinfo_ c 
JOIN bank_churn_ b 
ON c.CustomerID=b.CustomerID
JOIN activecustomer_ a 
ON b.ActiveID=a.ActiveID
WHERE Surname LIKE '%on';
 
-- Task-26. Can you observe any data disrupency in the Customer’s data? 
-- As a hint it’s present in the IsActiveMember and Exited columns. 
-- One more point to consider is that the data in the Exited Column is absolutely correct and accurate.

SELECT 
    c.CustomerID, 
    c.Surname, 
    b.ActiveID, 
    b.ExitID
    FROM bank_churn_ b 
JOIN customerinfo_ c 
ON b.CustomerID=c.CustomerID
WHERE b.ActiveID= 1 AND b.ExitID = 1;



