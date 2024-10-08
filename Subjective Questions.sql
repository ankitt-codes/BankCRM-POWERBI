-- Task-1. Customer Behavior Analysis: What patterns can be observed in the spending habits of long-term customers compared to new customers, and what might these patterns suggest about customer loyalty?

WITH CustomerBehavior AS (
    SELECT 
        CustomerID,
        Balance,
        NumOfProducts,
        CreditID,  -- Assuming CreditID represents whether they have a credit card (1 = Yes, 0 = No)
        CASE 
            WHEN Tenure >= 5 THEN 'Long-term' 
            ELSE 'New' 
        END AS CustomerType
    FROM Bank_Churn_
)
SELECT 
    CustomerType, 
    AVG(Balance) AS AvgBalance, 
    AVG(NumOfProducts) AS AvgNumOfProducts,
    AVG(CreditID) AS AvgCreditCardUsage
FROM CustomerBehavior
GROUP BY CustomerType;

-- Task-2. Product Affinity Study: Which bank products or services are most commonly used together, and how might this influence cross-selling strategies?

SELECT 
    COUNT(CASE WHEN CreditID = 1 AND NumOfProducts > 1 THEN 1 END) AS CreditCardAndMultipleProducts,
    COUNT(CASE WHEN ActiveID = 1 AND NumOfProducts > 1 THEN 1 END) AS ActiveAndMultipleProducts,
    COUNT(CASE WHEN CreditID = 1 AND ActiveID = 1 THEN 1 END) AS CreditCardAndActive
FROM 
    Bank_Churn_;
    
-- Task-3. Geographic Market Trends: How do economic indicators in different geographic regions correlate with the number of active accounts and customer churn rates?

WITH CustomerData AS (
    SELECT 
        c.GeographyID,
        COUNT(b.CustomerID) AS TotalCustomers,
        SUM(CASE WHEN b.ActiveID = 1 THEN 1 ELSE 0 END) AS ActiveAccounts,
        SUM(CASE WHEN b.ExitID = 1 THEN 1 ELSE 0 END) AS ChurnedCustomers
    FROM 
        Bank_Churn_ b 
        JOIN CustomerInfo_ c 
        ON b.CustomerID=c.CustomerID
    GROUP BY 
        GeographyID
)

SELECT 
    GeographyID,
    ActiveAccounts,
    TotalCustomers,
    ChurnedCustomers,
    (ChurnedCustomers * 1.0 / TotalCustomers) AS ChurnRate
FROM 
    CustomerData;
    
-- Task-4. Risk Management Assessment: Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank, and why?

WITH CustomerRiskData AS (
    SELECT 
        g1.GeographyLocation,
        CASE 
            WHEN c.Age < 30 THEN '18-29'
            WHEN c.Age >= 30 AND Age < 50 THEN '30-49'
            ELSE '50+'
        END AS AgeGroup,
        g.GenderCategory,
        AVG(c.EstimatedSalary) AS AvgIncome,
        AVG(b.CreditScore) AS AvgCreditScore,
        AVG(b.Balance) AS AvgBalance,
        COUNT(b.CustomerID) AS TotalCustomers,
        SUM(CASE WHEN b.ExitID= 1 THEN 1 ELSE 0 END) AS ChurnedCustomers
    FROM 
        Bank_Churn_ b 
	JOIN CustomerInfo_ c 
    ON c.CustomerID=b.CustomerID
    JOIN Gender_ g 
    ON c.GenderID=g.GenderID
    JOIN Geography_ g1
    ON c.GeographyID=g1.GeographyID
    GROUP BY 
        g1.GeographyLocation, AgeGroup, g.GenderCategory
)
SELECT 
    GeographyLocation,
    AgeGroup,
    GenderCategory,
    AvgIncome,
    AvgCreditScore,
    AvgBalance,
    TotalCustomers,
    ChurnedCustomers,
    (ChurnedCustomers * 1.0 / TotalCustomers) AS ChurnRate
FROM 
    CustomerRiskData
ORDER BY AgeGroup;

-- Task-5. Customer Tenure Value Forecast: How would you use the available data to model and predict the lifetime (tenure) value in the bank of different customer segments?


WITH CustomerData AS (
    SELECT 
        ci.CustomerID,
        ci.GenderID,
        ci.GeographyID,
        ci.EstimatedSAlary,
        bc.Tenure,
        bc.Balance,
        bc.ExitID
    FROM 
        CustomerInfo_ ci
    JOIN 
        Bank_Churn_ bc ON ci.CustomerID = bc.CustomerID
)

-- Step 2: Calculate Average Revenue and Average Customer Lifespan
, CustomerLTV AS (
    SELECT 
        GenderID,
        GeographyID,
        AVG(EstimatedSalary) AS AvgRevenuePerCustomer,
        AVG(Tenure) AS AvgCustomerLifespan,
        COUNT(CustomerID) AS TotalCustomers,
        SUM(CASE WHEN ExitID = 1 THEN 1 ELSE 0 END) AS ChurnedCustomers
    FROM 
        CustomerData
    GROUP BY 
        GenderID, GeographyID
)

-- Step 3: Calculate LTV
SELECT 
    GenderID,
    GeographyID,
    AvgRevenuePerCustomer,
    AvgCustomerLifespan,
    (AvgRevenuePerCustomer * AvgCustomerLifespan) AS LTV,
    TotalCustomers,
    ChurnedCustomers,
    (ChurnedCustomers * 1.0 / TotalCustomers) AS ChurnRate
FROM 
    CustomerLTV;
    
-- Task-7. Customer Exit Reasons Exploration: Can you identify common characteristics or trends among customers who have exited that could explain their reasons for leaving?

WITH ExitedCustomers AS (
    SELECT 
        ci.CustomerID,
        ci.GenderID,
        ci.GeographyID,
        ci.EstimatedSalary,
        bc.Tenure,
        bc.Balance,
        bc.ExitID,
        COUNT(bc.NumOfProducts) AS NumberOfProducts -- Assuming there’s a Products table linking customers to their products
    FROM 
        CustomerInfo_ ci
    JOIN 
        Bank_Churn_ bc ON ci.CustomerID = bc.CustomerID
    WHERE 
        bc.ExitID = 1
    GROUP BY 
        ci.CustomerID, ci.GenderID, ci.GeographyID, ci.EstimatedSalary, bc.Tenure, bc.Balance
)

SELECT 
    GenderID,
    GeographyID,
    AVG(EstimatedSalary) AS AvgIncome,
    AVG(Tenure) AS AvgTenure,
    AVG(Balance) AS AvgBalance,
    AVG(NumberOfProducts) AS AvgProductsUsed,
    COUNT(CustomerID) AS NumberOfExits
FROM 
    ExitedCustomers
GROUP BY 
    GenderID, GeographyID
ORDER BY 
    NumberOfExits DESC;

-- Task-9. Utilize SQL queries to segment customers based on demographics and account details.

SELECT 
    g.GeographyLocation,
    g1.GenderCategory,
    COUNT(ci.CustomerID) AS CustomerCount,
    AVG(bc.Balance) AS AvgBalance,
    AVG(bc.Tenure) AS AvgTenure
FROM 
    CustomerInfo_ ci
JOIN 
    Bank_Churn_ bc ON ci.CustomerID = bc.CustomerID
JOIN Geography_ g 
ON ci.GeographyID=g.GeographyID
JOIN Gender_ g1 
ON ci.GenderID=g1.GenderID
GROUP BY 
    g.GeographyLocation, g1.GenderCategory
ORDER BY 
    g.GeographyLocation, g1.GenderCategory;
  
-- Task-11. What is the current churn rate per year and overall as well in the bank? 
-- Over all 
SELECT 
    (SUM(CASE WHEN ExitID = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(CustomerID)) AS OverallChurnRate
FROM 
    Bank_Churn_;
-- Year wise 
SELECT 
    YEAR(c.BankDOJ) AS Year,
    (SUM(CASE WHEN b.ExitID = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(b.CustomerID)) AS AnnualChurnRate
FROM 
    Bank_Churn_ b 
JOIN CustomerInfo_ c 
ON b.CustomerID=c.CustomerID
GROUP BY 
    YEAR(c.BankDOJ)
ORDER BY 
    Year;
    
-- Task- In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?

ALTER TABLE Bank_Churn_ 
CHANGE COLUMN HasCrCard Has_creditcard INT;


