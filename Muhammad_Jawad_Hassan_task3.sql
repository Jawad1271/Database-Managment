USE [CRA];
GO

-- 1. Additional services provided by TELE2
SELECT a.additionalServiceName,
       oa.price
FROM OperatorAdditionalService oa
INNER JOIN AdditionalService a
    ON oa.additionalServiceID = a.additionalServiceID
INNER JOIN MobileNetworkOperator o
    ON oa.operatorID = o.operatorID
WHERE o.operatorName = 'TELE2'
ORDER BY a.additionalServiceName;
GO


-- 2. Additional services provided by all operators
SELECT o.operatorName,
       a.additionalServiceName,
       oa.price
FROM OperatorAdditionalService oa
INNER JOIN AdditionalService a
    ON oa.additionalServiceID = a.additionalServiceID
INNER JOIN MobileNetworkOperator o
    ON oa.operatorID = o.operatorID
ORDER BY o.operatorName, a.additionalServiceName;
GO


-- 3. Number of countries in each zone
SELECT z.zoneName,
       COUNT(c.countryCode) AS CountryCount
FROM Zone z
LEFT JOIN Country c
    ON z.zoneID = c.zoneID
GROUP BY z.zoneID, z.zoneName
ORDER BY z.zoneName;
GO


-- 4. Operator offering the most expensive calls to Mexico
SELECT TOP (1) WITH TIES
       o.operatorName
FROM ServicePriceInZone sp
INNER JOIN MobileNetworkOperator o
    ON sp.operatorID = o.operatorID
INNER JOIN Service s
    ON sp.serviceID = s.serviceID
INNER JOIN Country c
    ON sp.zoneID = c.zoneID
WHERE c.countryName = 'Mexico'
  AND s.serviceName = 'Calls'
  AND sp.price IS NOT NULL
ORDER BY sp.price DESC;
GO


-- 5. Lowest price per MB among internet data plans
--    that are not included in any mobile plan
SELECT TOP (1) WITH TIES
       o.operatorName,
       i.internetDataPlanName,
       CAST(
           i.price / NULLIF(i.dataAllowanceMB, 0)
           AS DECIMAL(18, 8)
       ) AS PricePerMB
FROM InternetDataPlan i
INNER JOIN MobileNetworkOperator o
    ON i.operatorID = o.operatorID
WHERE i.dataAllowanceMB > 0
  AND i.price IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM [Plan] p
      WHERE p.internetDataPlanID = i.internetDataPlanID
  )
ORDER BY i.price / NULLIF(i.dataAllowanceMB, 0);
GO


-- 6. Percentage distribution of subscribers among operators
SELECT o.operatorName,
       CAST(
           COUNT(s.subscriberID) * 100.0
           / NULLIF((SELECT COUNT(*) FROM Subscriber), 0)
           AS DECIMAL(5, 2)
       ) AS SubscriberPercentage
FROM MobileNetworkOperator o
LEFT JOIN [Plan] p
    ON o.operatorID = p.operatorID
LEFT JOIN Subscriber s
    ON p.planID = s.planID
GROUP BY o.operatorID, o.operatorName
ORDER BY SubscriberPercentage DESC, o.operatorName;
GO


-- 7. Three most popular mobile plans, including ties
SELECT TOP (3) WITH TIES
       p.planName,
       COUNT(*) AS SubscriberCount
FROM [Plan] p
INNER JOIN Subscriber s
    ON p.planID = s.planID
GROUP BY p.planID, p.planName
ORDER BY COUNT(*) DESC;
GO


-- 8. Ten randomly selected subscribers
--    Indicators check for any recorded order, including cancelled ones.
SELECT TOP (10)
       CONCAT(pe.firstName, ' ', pe.lastName) AS FullName,
       c.cityName,
       s.phoneNumber,
       s.contractStartDate,
       s.contractEndDate,
       o.operatorName,
       p.planName,
       CASE WHEN EXISTS (
           SELECT 1
           FROM OrderedInternetDataPlan oi
           WHERE oi.subscriberID = s.subscriberID
       ) THEN 'Yes' ELSE 'No'
       END AS AdditionalInternetOrdered,
       CASE WHEN EXISTS (
           SELECT 1
           FROM OrderedAdditionalService oa
           WHERE oa.subscriberID = s.subscriberID
       ) THEN 'Yes' ELSE 'No'
       END AS AdditionalServicesOrdered
FROM Subscriber s
INNER JOIN Person pe
    ON s.personID = pe.personID
INNER JOIN City c
    ON pe.cityID = c.cityID
INNER JOIN [Plan] p
    ON s.planID = p.planID
INNER JOIN MobileNetworkOperator o
    ON p.operatorID = o.operatorID
ORDER BY NEWID();
GO


-- 9. Top five subscribers by calls within Lithuania in October 2013
--    Counts calls that both start and end in Lithuania.
SELECT TOP (5)
       s.subscriberID,
       CONCAT(pe.firstName, ' ', pe.lastName) AS FullName,
       s.phoneNumber,
       COUNT(*) AS CallCount
FROM P2PConnection pc
INNER JOIN Subscriber s
    ON pc.subscriberID = s.subscriberID
INNER JOIN Person pe
    ON s.personID = pe.personID
INNER JOIN Service sv
    ON pc.serviceID = sv.serviceID
INNER JOIN Country origin
    ON pc.connectionInitializationPlace = origin.countryCode
INNER JOIN Country destination
    ON pc.recipientCountry = destination.countryCode
WHERE sv.serviceName = 'Calls'
  AND origin.countryName = 'Lithuania'
  AND destination.countryName = 'Lithuania'
  AND pc.connectionStart >= '20131001'
  AND pc.connectionStart < '20131101'
GROUP BY s.subscriberID,
         pe.firstName,
         pe.lastName,
         s.phoneNumber
ORDER BY COUNT(*) DESC, s.subscriberID;
GO


-- 10. Most popular foreign country by calls, including all ties
SELECT TOP (1) WITH TIES
       c.countryName,
       COUNT(*) AS CallCount
FROM P2PConnection pc
INNER JOIN Country c
    ON pc.recipientCountry = c.countryCode
INNER JOIN Service s
    ON pc.serviceID = s.serviceID
WHERE c.countryName <> 'Lithuania'
  AND s.serviceName = 'Calls'
GROUP BY c.countryCode, c.countryName
ORDER BY COUNT(*) DESC;
GO