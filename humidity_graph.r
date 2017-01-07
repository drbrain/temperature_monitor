require(graphics)
library("scales")
source("db.r")

# fetch data
living_room <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as humid
FROM device_history_1488211271
WHERE ts > now() - interval '24 hours'
ORDER BY time")

bedroom <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as humid
FROM device_history_718881295
WHERE ts > now() - interval '24 hours'
ORDER BY time")

master_bath <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as humid
FROM device_history_1086096036
WHERE ts > now() - interval '24 hours'
ORDER BY time")

downstairs <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as humid
FROM device_history_213679116
WHERE ts > now() - interval '24 hours'
ORDER BY time")

garage <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as humid
FROM device_history_1207524496
WHERE ts > now() - interval '24 hours'
ORDER BY time")

outside <- query(con, "
SELECT date_trunc('minute', ts) as time, sensorvalue as humid
FROM device_history_1647239515
WHERE ts > now() - interval '24 hours'
ORDER BY time")

kbfi <- query(con, "
SELECT ts as time, CAST(humidity AS float) as humid
FROM device_history_1095803503
WHERE ts > now() - interval '24 hours'
ORDER BY time")

humidifier <- query(con, "
SELECT ts as time,
       onoffstate as on
FROM device_history_771222970
WHERE ts > now() - interval '24 hours'")

# calculate humidifier on/off box dimensions
if (nrow(humidifier) > 0) {
  now <- Sys.time()

  humidifier_starts_on <- !humidifier[1,]$on
  humidifier_ends_on   <-  humidifier[nrow(humidifier),]$on

  if (humidifier_starts_on) {
    start_on <- data.frame(time=now - 86400, on=TRUE)

    humidifier <- rbind(start_on, humidifier)
  }

  if (humidifier_ends_on) {
    end_off <- data.frame(time=now, on=FALSE)

    humidifier <- rbind(humidifier, end_off)
  }

  humidifier_boxes <- humidifier[(filter(humidifier,c(-1,1))!=0)[,2],]
  humidifier_boxes <- humidifier_boxes[complete.cases(humidifier_boxes),]
  humidifier_boxes <- rbind(humidifier_boxes, humidifier[nrow(humidifier),])

  humidifier_on_off <- matrix(humidifier_boxes$time, ncol=2, byrow=TRUE)
}

# plot info
x_range   <- as.POSIXct(range(living_room$time,
                              kbfi$time,
                              downstairs$time,
                              bedroom$time,
                              master_bath$time,
                              garage$time,
                              outside$time),
                        "hours", tz="PST")
y_range   <- range(living_room$humid,
                   kbfi$humid,
                   downstairs$humid,
                   bedroom$humid,
                   master_bath$humid,
                   garage$humid,
                   outside$humid)

titles <- c(
  "Living Room",
  "KBFI",
  "Downstairs",
  "Bedroom",
  "Master Bath",
  "Garage",
  "Outside"
)

colors    <- c("black", "red", "chocolate", "lightsalmon", "gray50", "red4", "darkred", "darkgreen")
plot_char <- c(0, 1, 4, 4, 4, 4, 4, 1)
line_type <- c(1, 1, 1, 1, 1, 1, 1, 0)

png(filename="~/Sites/humidity.png",
    height=750, width=1000, bg="white")

plot.new()
plot.window(x_range, y_range)

# box
box()

# x axis
x_axis_range <- round(x_range, "hours")

axis.POSIXct(1, at=seq(x_axis_range[1], x_axis_range[2], by="hour"),
             format="%H:%M", las=1)

# y axis
axis(4, at=seq(y_range[1], y_range[2], by=2), las=1)

abline(h=seq(y_range[1], y_range[2], by=1), col="gray", lty="dotted")

# titles
title(main="Home Humidity", font.main=4)
title(ylab="Relative Humidity")

# humidifier on/off boxes on background
draw_humidifier_box <- function(row) {
  rect(row[1], min(y_range), row[2], max(y_range), col=alpha("red", 0.15), border=0)
}

if (nrow(humidifier) > 0) {
  apply(humidifier_on_off, 1, draw_humidifier_box)
}

# lines
lines(living_room$time, smooth(living_room$humid), col=colors[1], pch=plot_char[1], type="l")

lines(kbfi$time,        kbfi$humid,                col=colors[2], pch=plot_char[2], type="o")
lines(downstairs$time,  downstairs$humid,          col=colors[3], pch=plot_char[3], type="o")
lines(bedroom$time,     bedroom$humid,             col=colors[4], pch=plot_char[4], type="o")
lines(master_bath$time, master_bath$humid,         col=colors[5], pch=plot_char[5], type="o")
lines(garage$time,      garage$humid,              col=colors[6], pch=plot_char[6], type="o")
lines(outside$time,     outside$humid,             col=colors[7], pch=plot_char[7], type="o")

latest_living_room <- tail(living_room, 1)
text(latest_living_room$time, latest_living_room$humid, latest_living_room$humid, col=colors[1], pos=4)

# legend
legend('bottomleft', y_range[1],
       titles, col=colors,
       pch=plot_char, lty=line_type)

dev.off()

