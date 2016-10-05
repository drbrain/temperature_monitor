require(graphics)
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

# fetch data
living_room <- query(con, "
SELECT date_trunc('minute', ts) as time, avg(CAST(value AS float)) as temp
FROM variable_history_106354805
WHERE ts > now() - interval '24 hours'
GROUP BY date_trunc('minute', ts)
ORDER BY time")

bedroom <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as temp
FROM device_history_1818915597
WHERE ts > now() - interval '24 hours'
  AND sensorvalue_ui LIKE '%F'
ORDER BY time")

master_bath <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as temp
FROM device_history_286865561
WHERE ts > now() - interval '24 hours'
  AND sensorvalue_ui LIKE '%F'
ORDER BY time")

downstairs <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as temp
FROM device_history_1249580773
WHERE ts > now() - interval '24 hours'
  AND sensorvalue_ui LIKE '%F'
ORDER BY time")

outside <- query(con, "
SELECT ts as time, CAST(value AS float) as temp
FROM variable_history_343161330
WHERE ts > now() - interval '24 hours'
ORDER BY time")

desired <- query(con, "
SELECT date_trunc('minute', ts) as time,
       last_value(CAST(value AS float)) OVER
         (PARTITION BY date_trunc('minute', ts)) as temp
FROM variable_history_1868457272
WHERE ts > now() - interval '24 hours'
ORDER BY ts")

fire_on <- query(con, "
SELECT ts as time
FROM device_history_258380618
WHERE binaryoutputsall = '1'
  AND ts > now() - interval '24 hours'")

fire_off <- query(con, "
SELECT ts as time
FROM device_history_258380618
WHERE binaryoutputsall = '0'
  AND ts > now() - interval '24 hours'")


# plot info
x_range   <- as.POSIXct(range(living_room$time, outside$time, downstairs$time,
bedroom$time, master_bath$time),
                        "hours", tz="PST")
y_range   <- range(living_room$temp, outside$temp, downstairs$temp,
bedroom$temp, master_bath$temp)

titles <- c(
  "Living Room",
  "Desired",
  "Outside",
  "Downstairs",
  "Bedroom",
  "Master Bath"
)

colors    <- c("black", "darkgreen", "red", "chocolate", "lightsalmon", "gray50")
plot_char <- c(0, 1, 1, 4, 4, 4)
line_type <- c(1, 0, 1, 1, 1, 1)

png(filename="~/Sites/temperature.png",
    height=750, width=1000, bg="white")

# living_room
plot(living_room$time, smooth(living_room$temp),
     ylim=y_range, pch=plot_char[1], col=colors[1], type="l",
     ann=FALSE, axes=FALSE)

# desired
points(desired$time,    desired$temp,     col=colors[2], pch=plot_char[2])
text(desired$time,      desired$temp,     desired$temp, col=colors[2], pos=4)

# outside
lines(outside$time,     outside$temp,     col=colors[3], pch=plot_char[3], type="o")
lines(downstairs$time,  downstairs$temp,  col=colors[4], pch=plot_char[4], type="o")
lines(bedroom$time,     bedroom$temp,     col=colors[5], pch=plot_char[5], type="o")
lines(master_bath$time, master_bath$temp, col=colors[6], pch=plot_char[6], type="o")

# fire on vertical lines
lapply(fire_on$time, function(x) abline(v=x, col="red"))

# fire off vertical lines
lapply(fire_off$time, function(x) abline(v=x, col="blue"))

# box
box()

# x axis + one hour
axis.POSIXct(1, at=seq(x_range[1], x_range[2] + 3600, by="hour"),
             format="%H:00", las=1)

# y axis
axis(2, at=seq(y_range[1], y_range[2], by=2), las=1)

# titles
title(main="Home Temperature", font.main=4)
title(ylab="Degrees F")

# legend
legend('bottomright', y_range[1],
       titles, col=colors,
       pch=plot_char, lty=line_type)

dev.off()

