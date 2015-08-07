require(graphics)
library("DBI")
library("RPostgreSQL")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="indigo_history", user="indigo", host="emerson.local")

query <- function(con, query) {
  rs <- dbSendQuery(con, query)

  data <- fetch(rs, n = -1)

  dbClearResult(rs)

  data
}

# fetch data
living_room <- query(con, "
SELECT date_trunc('minute', ts) as time, avg(temperature) as temp
FROM living_room_temperatures
WHERE ts > now() - interval '24 hours'
GROUP BY date_trunc('minute', ts)
ORDER BY time")

outside <- query(con, "
SELECT ts as time, temperature as temp
FROM outside_temperatures
WHERE ts > now() - interval '24 hours'
ORDER BY time")

desired <- query(con, "
SELECT date_trunc('minute', ts) as time,
       last_value(temperature) OVER
         (PARTITION BY date_trunc('minute', ts)) as temp
FROM desired_temperatures
WHERE ts > now() - interval '24 hours'
ORDER BY ts")

fire_on <- query(con, "
SELECT ts as time
FROM device_history_multi_io
WHERE dev_name = 'Fireplace'
  AND output_binary_states = '1'
  AND ts > now() - interval '24 hours'")

fire_off <- query(con, "
SELECT ts as time
FROM device_history_multi_io
WHERE dev_name = 'Fireplace'
  AND output_binary_states = '0'
  AND ts > now() - interval '24 hours'")

# plot info
x_range   <- as.POSIXct(range(living_room$time, outside$time),
                        "hours", tz="PST")
y_range   <- range(living_room$temp, outside$temp)
colors    <- c("black", "darkgreen", "red")
plot_char <- c("", "o", "o")
line_type <- c(1, 0, 1)

png(filename="/Users/drbrain/Sites/temperature.png",
    height=750, width=1000, bg="white")

# living_room
plot(living_room$time, smooth(living_room$temp),
     ylim=y_range, pch=plot_char[1], col=colors[1], type="l",
     ann=FALSE, axes=FALSE)

# desired
points(desired$time, desired$temp, pch=plot_char[2], col=colors[2])
text(desired$time, desired$temp, desired$temp, pos=4, col=colors[2])

# outside
lines(outside$time, outside$temp, type=plot_char[3], col=colors[3])

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
legend(min(living_room$time), y_range[2],
       c("Living Room", "Desired", "Outside"), col=colors,
       pch=plot_char, lty=line_type)

dev.off()

