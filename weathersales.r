install.packages("RPostgreSQL")

require("RPostgreSQL")

# create a connection
pw <- {
  "[replace with your password here]"
}

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")


# creates a connection to the postgres database
# IMPORTANT: ensure connection settings match those of your own
con <- dbConnect(drv, dbname = "chinook",
                 host = "localhost", port = 5433,
                 user = "postgres", password = pw)
rm(pw) # removes the password


# read "WeatherSales" postgresql table into "sales" dataframe
sales <- dbReadTable(con,"WeatherSales")


# create regression line object
regrLine <- lm(sales$UnitsSoldCnt~sales$TempAvg)

# create scatterplot of (sales$TempAvg, sales$UnitsSoldCnt) pairs
plot(sales$TempAvg, sales$UnitsSoldCnt, xlab="Average Temperature (F)", ylab="Units Sold")

title("Weather Sales Relationship with Regression Line")

# plot regression line over scatterplot
abline(regrLine) 
