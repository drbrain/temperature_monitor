library("DBI")
library("RPostgreSQL")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="indigo_history", user="indigo", host="localhost")

query <- function(con, query) {
  rs <- dbSendQuery(con, query)

  data <- fetch(rs, n = -1)

  dbClearResult(rs)

  data
}

