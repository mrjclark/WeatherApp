geoapi=https://nominatim.openstreetmap.org/search?q=17+Strada+Pictor+Alexandru+Romano%2C+Bukarest&format=geojson
histweatherapi=https://archive-api.open-meteo.com/v1/archive?latitude=$1&longitude=$2&start_date=$3&end_date=$4&hourly=$5&timezone=$6
weatherapi=https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current=temperature_2m,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m
#!/data/data/com.termux/files/usr/bin/bash

lat=$1
long=$2
startDate=$3
endDate=$4
dataSource=$5


if (( dataSource == 'SQL' )); do
  sqlite-utils.getPressure $1 $2 $3 $4
elif (( datasource == 'WEB' )); do
  api-utils.getPressure $1 $2 $3 $4
else; do
  err=error-utils.raiseError $5 "Not availble"
  return err
fi


