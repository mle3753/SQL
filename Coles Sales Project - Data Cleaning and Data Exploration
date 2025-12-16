-- Data Cleaning

-- Skills used:
-- 3. Analysing Null Values or Blank Values
-- 4. Removing Any Unnecessary Columns and Rows


SELECT *
FROM coles_sales_raw;

SELECT *
FROM coles_store_raw;


-- Create Duplicates of the Raw Tables

CREATE TABLE coles_sales_staging
LIKE coles_sales_raw;

INSERT coles_sales_staging
SELECT *
FROM coles_sales_raw;

CREATE TABLE coles_store_staging
LIKE coles_store_raw;

INSERT coles_store_staging
SELECT *
FROM coles_store_raw;

SELECT *
FROM coles_sales_staging;

SELECT *
FROM coles_store_staging;


-- Checking for Null Values or Blank Values

SELECT *
FROM coles_sales_staging
WHERE Sales_Cost IS NULL OR Sales_Cost = ' '
AND Coles_Forecast IS NULL OR Coles_Forecast = ' ';

SELECT *
FROM coles_store_staging
WHERE Customer_Count IS NULL OR Customer_Count = ' ';


-- Removing Null Values from coles_sales_staging Since They are a Small Portion of the Data

DELETE
FROM coles_sales_staging
WHERE Sales_Cost IS NULL OR Sales_Cost = ' '
AND Coles_Forecast IS NULL OR Coles_Forecast = ' ';


-- Adding Net Sales Column

ALTER TABLE coles_sales_staging
ADD COLUMN Net_Sale INT 
	AS (Gross_Sale - Sales_Cost) STORED
	AFTER Sales_Cost;


-- Exploratory Analysis

SELECT *
FROM coles_sales_staging;

SELECT *
FROM coles_store_staging;


-- Create a view of the joined table of coles_store_staging + coles_sales_staging

CREATE VIEW coles_combined_staging AS
SELECT *
FROM coles_sales_staging AS csales
INNER JOIN coles_store_staging AS cstore
	ON csales.Coles_StoreIDNo = cstore.Coles_StoreID
ORDER BY Coles_StoreIDNo;


-- Shows the total net sales for each state

SELECT Store_Location, COUNT(Coles_StoreID) AS Num_of_Stores, SUM(Net_Sale) AS Total_Net_Sales
FROM coles_combined_staging
GROUP BY Store_Location
ORDER BY Total_Net_Sales DESC;


-- Shows the total expected revenue for each state

SELECT Store_Location, COUNT(Coles_StoreID) AS Num_of_Stores, SUM(Expec_Revenue) AS Total_Expec_Revenue
FROM coles_combined_staging
GROUP BY Store_Location
ORDER BY Total_Expec_Revenue DESC;


-- Shows the percentage of stores that are "On Target" for each state

SELECT Store_Location, 
SUM(Coles_Forecast = 'On Target') AS Num_On_Target,
COUNT(Coles_StoreID) AS Num_of_Stores,
ROUND((SUM(Coles_Forecast = 'On Target') / COUNT(Coles_StoreID)) *100, 2) AS Percentage_Of_Stores_On_Target
FROM coles_combined_staging
GROUP BY Store_Location
ORDER BY Percentage_Of_Stores_On_Target DESC;


-- Shows the gross profit margin for each state

SELECT Store_Location, COUNT(Coles_StoreID) AS Num_of_Stores, 
SUM(Net_Sale) AS Total_Net_Sales, 
SUM(Gross_Sale) AS Total_Gross_Sales,
(SUM(Net_Sale) / SUM(Gross_Sale)) *100 AS Gross_Profit_Margin
FROM coles_combined_staging
GROUP BY Store_Location
ORDER BY Gross_Profit_Margin DESC;


-- Shows the overall ranking of each state based on the relevant metrics above

WITH state_summary AS (
    SELECT 
        Store_Location,
        SUM(Net_Sale) AS Total_Net_Sales,
        SUM(Expec_Revenue) AS Total_Expec_Revenue,
		ROUND((SUM(Coles_Forecast = 'On Target') / COUNT(Coles_StoreID)) *100, 2) AS Percentage_Of_Stores_On_Target,
        (SUM(Net_Sale) / SUM(Gross_Sale)) *100 AS Gross_Profit_Margin
	FROM coles_sales_staging AS csales
	INNER JOIN coles_store_staging AS cstore
		ON csales.Coles_StoreIDNo = cstore.Coles_StoreID
    GROUP BY Store_Location
), ranked AS (
	SELECT *,
       RANK() OVER (ORDER BY Total_Net_Sales DESC) AS Net_Sales_Rank,
       RANK() OVER (ORDER BY Total_Expec_Revenue DESC) AS Expec_Revenue_Rank,
       RANK() OVER (ORDER BY Percentage_Of_Stores_On_Target DESC) AS On_Target_Rank,
       RANK() OVER (ORDER BY Gross_Profit_Margin DESC) AS Gross_Profit_Margin_Rank
FROM state_summary
)
SELECT *,
	(Net_Sales_Rank + Expec_Revenue_Rank + On_Target_Rank + Gross_Profit_Margin_Rank) AS Overall_Score,
    RANK() OVER (ORDER BY (Net_Sales_Rank + Expec_Revenue_Rank + On_Target_Rank + Gross_Profit_Margin_Rank)) AS Overall_Rank
FROM ranked
ORDER BY Overall_Rank;


-- Shows the top 10 individual stores based on net sales per customer count

SELECT Coles_StoreID, Store_Location, Expec_Revenue, Net_Sale, Coles_Forecast, Customer_Count, 
(Net_Sale / Customer_Count) *100 AS Net_Sale_Per_Customer_Count
FROM coles_combined_staging
ORDER BY Net_Sale_Per_Customer_Count DESC
LIMIT 10;


-- Shows the bottom 10 individual stores based on net sales per customer count

SELECT Coles_StoreID, Store_Location, Expec_Revenue, Net_Sale, Coles_Forecast, Customer_Count, 
(Net_Sale / Customer_Count) *100 AS Net_Sale_Per_Customer_Count
FROM coles_combined_staging
WHERE Customer_Count IS NOT NULL
ORDER BY Net_Sale_Per_Customer_Count ASC
LIMIT 10;


-- Shows the top 10 individual stores based on net sales per staff count

SELECT Coles_StoreID, Store_Location, Expec_Revenue, Net_Sale, Coles_Forecast, Staff_Count, 
(Net_Sale / Staff_Count) AS Net_Sale_Per_Staff_Count
FROM coles_combined_staging
ORDER BY Net_Sale_Per_Staff_Count DESC
LIMIT 10;


-- Shows the bottom 10 individual stores based on net sales per staff count

SELECT Coles_StoreID, Store_Location, Expec_Revenue, Net_Sale, Coles_Forecast, Staff_Count, 
(Net_Sale / Staff_Count) AS Net_Sale_Per_Staff_Count
FROM coles_combined_staging
ORDER BY Net_Sale_Per_Staff_Count ASC
LIMIT 10;


-- Shows the top 10 individual stores based on net sales per store area

SELECT Coles_StoreID, Store_Location, Expec_Revenue, Net_Sale, Coles_Forecast, Store_Area, 
(Net_Sale / Store_Area) AS Net_Sale_Per_Store_Area
FROM coles_combined_staging
ORDER BY Net_Sale_Per_Store_Area DESC
LIMIT 10;


-- Shows the bottom 10 individual stores based on net sales per store area

SELECT Coles_StoreID, Store_Location, Expec_Revenue, Net_Sale, Coles_Forecast, Store_Area, 
(Net_Sale / Store_Area) AS Net_Sale_Per_Store_Area
FROM coles_combined_staging
ORDER BY Net_Sale_Per_Store_Area ASC
LIMIT 10;

SELECT Coles_StoreID, Store_Location, Expec_Revenue, Net_Sale, 
((Net_Sale - Expec_Revenue) / Expec_Revenue) *100 AS Revenue_Surplus
FROM coles_combined_staging
WHERE Store_Location = 'ACT'
ORDER BY Revenue_Surplus;


--  Deep Dive into Victoria Stores

-- Shows the total expected revenue, net sales, percentage of stores "On Target", 
-- revenue achievement and gross profit margin across the state of VIC

SELECT Store_Location, SUM(Expec_Revenue) AS Total_Expec_Revenue, SUM(Net_Sale) AS Total_Net_Sale,
ROUND((SUM(Coles_Forecast = 'On Target') / COUNT(Coles_StoreID)) *100, 2) AS Percentage_of_Stores_on_Target,
ROUND((SUM(Net_Sale) / SUM(Expec_Revenue)) *100, 2) AS Revenue_Achievement,
(SUM(Net_Sale) / SUM(Gross_Sale)) *100 AS Gross_Profit_Margin
FROM coles_combined_staging
WHERE Store_Location = 'VIC'
GROUP BY Store_Location;


-- Shows the stores in the state of VIC which most exceed their expected revenue

SELECT Coles_StoreID, Store_Location, Coles_Forecast, 
(Net_Sale - Expec_Revenue) AS Net_Sales_Above_Expec_Revenue,
Customer_Count, Staff_Count, Store_Area
FROM coles_combined_staging
WHERE Store_Location = 'VIC'
AND Net_Sale >= Expec_Revenue
ORDER BY Net_Sales_Above_Expec_Revenue DESC;


-- Shows the stores in the state of VIC which most fall short of their expected revenue

SELECT Coles_StoreID, Store_Location, Coles_Forecast, 
(Net_Sale - Expec_Revenue) AS Net_Sales_Below_Expec_Revenue,
Customer_Count, Staff_Count, Store_Area
FROM coles_combined_staging
WHERE Store_Location = 'VIC'
AND Net_Sale < Expec_Revenue
ORDER BY Net_Sales_Below_Expec_Revenue ASC;


-- Shows the net sales per customer count, staff count and store area for each store in the state of VIC

SELECT Coles_StoreID, Store_Location, Coles_Forecast,
(Net_Sale / Customer_Count) *100 AS Net_Sale_Per_Customer_Count,
(Net_Sale / Staff_Count) AS Net_Sale_Per_Staff_Count,
(Net_Sale / Store_Area) AS Net_Sale_Per_Store_Area
FROM coles_combined_staging
WHERE Store_Location = 'VIC';

