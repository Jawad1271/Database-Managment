
USE [CRA];
GO

-- 1. Number of cities.
SELECT COUNT(*) AS CityCount
FROM City;
GO

-- 2. Plans that include an internet data plan.
SELECT p.planName AS PlanName,
       p.price AS PlanPrice,
       i.internetDataPlanName AS InternetDataPlanName,
       i.dataAllowanceMB AS DataAllowanceMB,
       i.price AS InternetDataPlanPrice,
       o.operatorName AS OperatorName
FROM [Plan] AS p
INNER JOIN InternetDataPlan AS i
    ON p.internetDataPlanID = i.internetDataPlanID
INNER JOIN MobileNetworkOperator AS o
    ON i.operatorID = o.operatorID;
GO



-- 4. Number of users in each city, including cities with no users.
SELECT c.cityName AS CityName, COUNT(p.personID) AS UserCount
FROM City AS c
LEFT JOIN Person AS p ON c.cityID = p.cityID
GROUP BY c.cityID, c.cityName
ORDER BY c.cityName;
GO

-- 5. Cities with no users.
SELECT c.cityName AS CityName
FROM City AS c
WHERE NOT EXISTS (
    SELECT 1 FROM Person AS p WHERE p.cityID = c.cityID
)
ORDER BY c.cityName;
GO

-- 6a. Average users per city, excluding cities with no users.
SELECT AVG(CAST(UserCount AS DECIMAL(18, 2))) AS AverageUsersPerCity
FROM (
    SELECT COUNT(p.personID) AS UserCount
    FROM City AS c
    INNER JOIN Person AS p ON c.cityID = p.cityID
    GROUP BY c.cityID
) AS CityUserCounts;
GO

-- 6b. Average users per city, including cities with no users.
SELECT AVG(CAST(UserCount AS DECIMAL(18, 2))) AS AverageUsersPerCity
FROM (
    SELECT COUNT(p.personID) AS UserCount
    FROM City AS c
    LEFT JOIN Person AS p ON c.cityID = p.cityID
    GROUP BY c.cityID
) AS CityUserCounts;
GO

-- 7. Operators with the most plans, including all ties.
SELECT TOP (1) WITH TIES
       o.operatorName AS OperatorName, COUNT(p.planID) AS PlanCount
FROM MobileNetworkOperator AS o
LEFT JOIN [Plan] AS p ON o.operatorID = p.operatorID
GROUP BY o.operatorID, o.operatorName
ORDER BY COUNT(p.planID) DESC;
GO

-- 8. Subscriptions starting January 3-10, 2025, inclusive.
SELECT pe.firstName AS FirstName,
       pe.lastName AS LastName,
       p.planName AS PlanName,
       s.contractStartDate AS ContractStartDate
FROM Subscriber AS s
INNER JOIN Person AS pe ON s.personID = pe.personID
INNER JOIN [Plan] AS p ON s.planID = p.planID
WHERE s.contractStartDate >= '20250103'
  AND s.contractStartDate < '20250111'
ORDER BY s.contractStartDate, pe.lastName, pe.firstName;
GO

-- 9. Average plan price per operator, highest first.

SELECT o.operatorName AS OperatorName, AVG(p.price) AS AveragePlanPrice
FROM MobileNetworkOperator AS o
LEFT JOIN [Plan] AS p ON o.operatorID = p.operatorID
GROUP BY o.operatorID, o.operatorName
ORDER BY AveragePlanPrice DESC;
GO

-- 10. Number of distinct additional services per operator.
SELECT o.operatorName AS OperatorName,
       COUNT(DISTINCT a.additionalServiceID) AS AdditionalServiceCount
FROM MobileNetworkOperator AS o
LEFT JOIN OperatorAdditionalService AS a ON o.operatorID = a.operatorID
GROUP BY o.operatorID, o.operatorName
ORDER BY o.operatorName;
GO


