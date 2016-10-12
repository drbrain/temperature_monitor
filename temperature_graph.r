require(graphics)
library("DBI")
library("RPostgreSQL")
library("scales")

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

fire <- query(con, "
SELECT ts as time,
       cast(binaryoutputsall as boolean) as on
FROM device_history_258380618
WHERE ts > now() - interval '24 hours'")

# calculate fire on/off box dimensions
now <- Sys.time()

fire_starts_on <- !fire[1,]$on
fire_ends_on   <-  fire[nrow(fire),]$on

if (fire_starts_on) {
  start_on <- data.frame(time=now - 86400, on=TRUE)

  fire <- rbind(start_on, fire)
}

if (fire_ends_on) {
  end_off <- data.frame(time=now, on=FALSE)

  fire <- rbind(fire, end_off)
}

fire_boxes <- fire[(filter(fire,c(-1,1))!=0)[,2],]
fire_boxes <- fire_boxes[complete.cases(fire_boxes),]
fire_boxes <- rbind(fire_boxes, fire[nrow(fire),])

fire_on_off <- matrix(fire_boxes$time, ncol=2, byrow=TRUE)

# plot info
x_range   <- as.POSIXct(range(living_room$time, outside$time, downstairs$time,
bedroom$time, master_bath$time),
                        "hours", tz="PST")
y_range   <- range(living_room$temp, outside$temp, downstairs$temp,
bedroom$temp, master_bath$temp)

titles <- c(
  "Living Room",
  "Outside",
  "Downstairs",
  "Bedroom",
  "Master Bath",
  "Desired"
)

colors    <- c("black", "red", "chocolate", "lightsalmon", "gray50", "darkgreen")
plot_char <- c(0, 1, 4, 4, 4, 1)
line_type <- c(1, 1, 1, 1, 1, 0)

png(filename="~/Sites/temperature.png",
    height=750, width=1000, bg="white")

plot.new()
plot.window(x_range, y_range)

# fire on/off boxes on background
draw_fire_box <- function(row) {
  rect(row[1], min(y_range), row[2], max(y_range), col=alpha("red", 0.15), border=0)
}

apply(fire_on_off, 1, draw_fire_box)

# lines
lines(living_room$time, smooth(living_room$temp), col=colors[1], pch=plot_char[1], type="l")
lines(outside$time,     outside$temp,             col=colors[2], pch=plot_char[2], type="o")
lines(downstairs$time,  downstairs$temp,          col=colors[3], pch=plot_char[3], type="o")
lines(bedroom$time,     bedroom$temp,             col=colors[4], pch=plot_char[4], type="o")
lines(master_bath$time, master_bath$temp,         col=colors[5], pch=plot_char[5], type="o")

# desired
points(desired$time,    desired$temp,             col=colors[6], pch=plot_char[6])
text(desired$time, desired$temp, desired$temp, col=colors[6], pos=4)

# box
box()

# x axis
x_axis_range <- round(x_range, "hours")

axis.POSIXct(1, at=seq(x_axis_range[1], x_axis_range[2], by="hour"),
             format="%H:%M", las=1)

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

