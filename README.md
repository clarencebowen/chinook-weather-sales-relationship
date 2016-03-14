# Weather and Music Sales Correlation

###Summary

The objective of this report is to measure the type and strength of relationship (if one exists)
between weather and music sales as provided in the [Chinook database](https://chinookdatabase.codeplex.com/). 
First, we should clarify what exactly is meant by "weather" and "sales".

After examining the Chinook database schema, we could define "sales" in one of several ways: 

1. Total number of invoices daily
2. Total number of invoice line items (tracks) purchased daily
3. Total number of unique customers daily

This reports takes (2) as the sales dependent variable.

Upon profiling the data, we should notice that invoice dates are indeed "daily" (the hour, minute, and second 
components of the Invoice Date column are all 0). It is very unlikely that, in this random dataset, all customers made purchases at exactly midnight.

Based upon this "daily" aggregate observation, we could now decide on some daily weather explanatory (or independent) variables. 
I make an assumption that weather affects a person's likelihood to stay indoors vs. outdoors, which in turn affects how much idle, sedentary time a person has to download music. I reason that the more "stationary" time a person has, such as being confined indoors due to severe weather, the more likely that person is to download and listen to music.

Given the previous assumption and "daily" breakout observation, some independent variables of interest could be:

1. daily average temperature (perhaps colder temperatures cause more people to stay indoors giving them more idle time to download music)
2. daily average humidity (perhaps the more humid it is out, the more likely people are to stay indoors giving them more idle time to download music)
3. daily average precipitation in inches (perhaps rain and snow cause more people to stay indoors giving them more idle time to download music)


We could choose one or a combination of these independent variables in our model.

For simplicity, this report will only explore (1) daily average temperature as our sole independent variable. Also for simplicity, we will assume a linear regression model, i.e., we hypothesize there is a *linear* relationship between "daily average temperature" and "Total number of invoice line items (tracks) purchased daily".

It is, therefore, the goal of this report to measure the strength of such *linear* relationship (if one exists).

**Note**: In reality, we should first perform some exploratory data analysis on our variables (such as drawing scatter plots), and then choose an appropriate regression model.


Next, we need to identify a data source (or sources) for our weather explanatory variables. Googling for open weather datasets using keywords "average daily weather" yields [Weather Base](http://www.weatherbase.com/) as one example website that contains an archive of seemingly accurate average daily weather measurements for cities globally. Let's assume that we were able to import the data into a table (via webscraping using PHP or Python, for example). However in this report, we actually create fictitious weather data generated randomly.


The following steps goes into details. 






###Setup and Testing

Software Required:
- [Postgres & pgAdmin III (recommended)] (http://www.postgresql.org/download/) 
- R/[RStudio] (https://www.rstudio.com/products/rstudio/download/)

Steps:

- Using pgAdmin III or console, create new database "chinook":  `CREATE DATABASE chinook WITH OWNER = postgres;`.
**Note**: User "postgres" is assumed to already exist, and have superuser privileges (as is typical in a new postgres installation). Default user "postgres" can be replaced with another user you define with similar privileges.

- Connect to database "chinook", and create the tables (with data) in "chinook" by running script: `Chinook_PostgreSql.sql` (located in this repo).

- Check that tables and data have been loaded properly.`CREATE TEMPORARY TABLE tbl_stats (table_name text, cnt int);  
INSERT INTO tbl_stats
SELECT 'Artist', COUNT(*) FROM "Artist"
UNION ALL
SELECT 'Employee', COUNT(*) FROM "Employee"
UNION ALL
SELECT 'Customer', COUNT(*) FROM "Customer"
UNION ALL
SELECT 'Invoice', COUNT(*) FROM "Invoice"
UNION ALL
SELECT 'InvoiceLine', COUNT(*) FROM "InvoiceLine"
UNION ALL
SELECT 'Playlist', COUNT(*) FROM "Playlist"
UNION ALL
SELECT 'WeatherSales', COUNT(*) FROM "WeatherSales"
UNION ALL
SELECT 'PlaylistTrack', COUNT(*) FROM "PlaylistTrack"
UNION ALL
SELECT 'Album', COUNT(*) FROM "Album"
UNION ALL
SELECT 'Genre', COUNT(*) FROM "Genre"
UNION ALL
SELECT 'MediaType', COUNT(*) FROM "MediaType"
UNION ALL
SELECT 'Track', COUNT(*) FROM "Track"
;
SELECT * FROM tbl_stats;
`

Your output should match:

table_name | cnt
--- | ---
`Artist`|`275`
`Employee`|`8`
`Customer`|`59`
`Invoice`|`412`
`InvoiceLine`|`2240`
`Playlist`|`18`
`PlaylistTrack`|`8715`
`Album`|`347`
`Genre`|`25`
`MediaType`|`5`
`Track`|`3503`

`DROP TABLE tbl_stats;`

- Run script to create and populate (random) weather data: `create_weather_tables.sql`

- Check that tables have been created and loaded properly: Execute `SELECT COUNT(*) FROM "DailyWeatherStats";`
Your output should yield 96301 rows where
96301 = 1817 (number of dates in range [2009-01-01, 2013-12-22] ) * 53 (number of customer city,state,country combination). Execute `SELECT COUNT(*) FROM "WeatherSales";`Your output should yield 411 rows. The grain of this table is ("City", "State", "Country", "Date")

- Do some preliminary analysis in postgresql before loading into R (for further analysis). Recall that we are assuming a linear regression model. We are looking for the best-fit line 
that goes through the plot of (X,Y) pairs taken from population with form:

Y = AX + B,

where Y is value of the dependent variable "Total number of invoice line items (tracks) purchased daily",
X is the value of the independent or explanatory variable "daily average temperature",
A is the slope of the population regression line, interpreted as the average change in the dependent variable (Y) for a 1-unit change in the independent variable (X), and
B is the y-intercept.

Using our sample data we can estimate the population regression line with y = ax + b.


PostgreSQL comes with some handy statistical functions for calculating "a", "b" and more:

Execute `
SELECT corr("UnitsSoldCnt","TempAvg"),
regr_slope("UnitsSoldCnt","TempAvg") AS a,
regr_intercept("UnitsSoldCnt","TempAvg") AS b
FROM "WeatherSales";`

Notice that the regression slope estimator "b" is approximately 0. Moreover the correlation between 
independent and dependent is also virtually 0.
From this we can we infer that there is no linear relationship between "TempAvg" and "UnitsSoldCnt".
We should expect this since the weather data was randomly generated. 
However, before making a conclusion let's explore the relationship further especially in terms of looking at the (x,y) scatterplot.
For this we'll use statistical tool R.

- Download weathersales.r to a directory on your computer RStudio can access. This script imports the WeatherSales table into R as a dataframe, and creates both a scatter plot and plot of linear regression line of the data.
- Open RStudio. Go to File>Open File..., and open weathersales.r
- Look for "[replace with your password here]", and replace with your password. For example, if your password is "pass123" then change line to `pw <- {"pass123"}`.
- Change connection settings for the "con" variable to those of your own.
- Save the file.
- Click on "Source" button (top-right). After a few seconds, a scatterplot with a regression line should have been plotted. The scatterplot should match that of this repo (weathersales.pdf). Note no discernable relationship in the scatterplot.
- In RStudio console, type "regrLine" and hit the "Enter" key.

Note the Intercept and linear regression slope match the values obtained
using the statistical functions in postgresql:
	`Intercept: 5.397684      Slope: 0.001008`  

Running `cor(sales$UnitsSoldCnt , sales$TempAvg)` should also obtain `0.00641842`


####Conclusion
Given the sample sales data in the chinook database and (randomly-generated) weather dataset, we were able to find a correlation of near-zero between total number of units sold and average daily temperature, suggesting little to no linear relationship. Moreover the scatterplot  appears to show no weather-sales relationship.

