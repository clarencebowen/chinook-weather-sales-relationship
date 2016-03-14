/* 
###
# The following creates and populates the weather table which stores independent variable "TempAvg"
# Other independent variables are included as well, and all data are generated randomly.
### 
*/

-- create table to store daily weather metrics
DROP TABLE IF EXISTS "DailyWeatherStats";
CREATE TABLE IF NOT EXISTS "DailyWeatherStats"
(
    "Date" DATE NOT NULL,
    "City" VARCHAR(40) NOT NULL,
    "State" VARCHAR(40),
    "Country" VARCHAR(40) NOT NULL,
    "TempAvg" NUMERIC(6,2),
    "HumidityAvg" NUMERIC(6,2),
    "PrecipAvg" NUMERIC(6,2)
);

-- set seed for random number generator for reproducibility
SELECT setseed(0.1);

-- populate with random data for daily avg temp, humidity, and precipitation within date range [min invoice date, max invoice date] = [2009-01-01, 2013-12-22]
INSERT INTO "DailyWeatherStats"("Date", "City", "State", "Country", "TempAvg", "HumidityAvg", "PrecipAvg")
SELECT 
generate_series(MIN(inv."InvoiceDate"::date), MAX(inv."InvoiceDate"::date), '1 day'::interval)::date  AS date
, cust."City", cust."State", cust."Country"
, random()*100 AS TempAvg  -- daily avg Fahr temp between 0 and 100 (inclusive) deg Fahr
, random()*100 AS HumidityAvg -- daily avg % humidity between 0 and 100 (inclusive)
, random()*6 AS PrecipAvg -- daily avg precipitation in inches
FROM "Invoice" inv, "Customer" cust
GROUP BY cust."City", cust."State", cust."Country"
;
/*
Check output:
SELECT COUNT(*) FROM "DailyWeatherStats"; -- should yield 96301 rows 
96301  = 1817 (number of dates in range [2009-01-01, 2013-12-22] ) * 53 (number of customer city,state,country combination)
*/





/* 
###
# The following creates and populates the WeatherSales table which stores independent variable "TempAvg"
# alongside dependent variable "UnitsSoldCnt". Other independent and dependent variables are included as well.
### 
*/

DROP TABLE IF EXISTS "WeatherSales";
CREATE TABLE IF NOT EXISTS "WeatherSales"
(
    "Date" DATE NOT NULL,
    "City" VARCHAR(40) NOT NULL,
    "State" VARCHAR(40),
    "Country" VARCHAR(40) NOT NULL,
    "TempAvg" NUMERIC(6,2),
    "HumidityAvg" NUMERIC(6,2),
    "PrecipAvg" NUMERIC(6,2),
    "UniqCustCnt" INT,
    "UnitsSoldUSD" NUMERIC(10,2) NOT NULL,
    "UnitsSoldCnt" INT
    
);


INSERT INTO "WeatherSales"
SELECT weather."Date", weather."City", weather."State", weather."Country",
weather."TempAvg", weather."HumidityAvg", weather."PrecipAvg"
,COUNT(distinct inv."CustomerId") as cust_cnt, 
SUM(invLine."Quantity" * invLine."UnitPrice") as units_sold_usd,
COUNT(invLine."Quantity") as units_sold
FROM "Invoice" inv 
INNER JOIN "InvoiceLine" invLine 
	ON inv."InvoiceId" = invLine."InvoiceId"
INNER JOIN "Track" tr 
	ON tr."TrackId" = invLine."TrackId"
INNER /*RIGHT*/ JOIN "DailyWeatherStats" weather --only use RIGHT JOIN for full data set, not sample
	ON weather."Date" = inv."InvoiceDate"::date AND weather."City" = inv."BillingCity" 
	AND coalesce(weather."State",'') = coalesce(inv."BillingState",'') AND weather."Country" = inv."BillingCountry"
GROUP BY weather."City", weather."State", weather."Country",weather."Date",weather."TempAvg", weather."HumidityAvg", weather."PrecipAvg"
;
/*
Check output:
SELECT COUNT(*) FROM "WeatherSales"; -- should yield 411 rows
*/