#!/bin/bash

set -eou pipefail

START_DATE="2020-01-01" # This is the defualt for if the DB doesn't exist
END_DATE=$(date +%Y-%m-%d)
WEATHER_DB="db_weather.db"
WEATHER_TABLE="weather"
WEATHER_JSON="weather-info.json"
WEATHER_CSV="weather-info.csv"
UPDATE_FILE="update_weather_db.sh"


trap "Error at line ${LINENO}" ERR

function getJson() {
	API_URL="https://archive-api.open-meteo.com/v1/archive?latitude=29.42&longitude=-95.46&start_date=$1&end_date=$2&hourly=temperature_2m,surface_pressure,relative_humidity_2m&timezone=America/Chicago"
	curl $API_URL > $3
	echo $API_URL
}

function jsonToCsv() {

	jq -r '
	  . as $root |
	  [range(0; $root.hourly.time | length)][] as $i |
	  [
	    $i,
	    $root.latitude,
	    $root.longitude,
	    $root.utc_offset_seconds,
	    $root.elevation,
	    $root.hourly.time[$i],
	    $root.hourly_units.time,
	    $root.timezone_abbreviation,
	    $root.hourly.temperature_2m[$i],
	    $root.hourly_units.temperature_2m,
	    $root.hourly.surface_pressure[$i],
	    $root.hourly_units.surface_pressure,
	    $root.hourly.relative_humidity_2m[$i],
	    $root.hourly_units.relative_humidity_2m
	  ] | @csv
	' "$1" > "$2"
}

function loadDb() {

	sqlite3 "$1" <<EOF
	.mode csv
	.import $2 $3
EOF
}

logEvent() {
	echo "$(date -Isecond) | $1 | $2" >> weatherApp.log
}

logError() {
	logEvent "ERROR" $1
}

logWarning() {
	logEvent "WARNING" $1
}

logInfo() {
	logEvent "INFO" $1
}

logDebug() {
	logEvent "DEBUG" $1
}

#!/bin/bash

# 📜 validate_inputs: Ensures all inputs are correctly formatted and within allowed ranges
validate_inputs() {
  local start_date="$1"
  local end_date="$2"
  local latitude="$3"
  local longitude="$4"
  local unit="$5"

  # Validate date format YYYY-MM-DD
  for date in "$start_date" "$end_date"; do
    if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "❌ Invalid date format: $date (expected YYYY-MM-DD)"
      return 1
    fi
  done

  # Validate numeric latitude and longitude
  for coord in "$latitude" "$longitude"; do
    if [[ ! "$coord" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
      echo "❌ Invalid coordinate: $coord (expected numeric)"
      return 1
    fi
  done

  # Validate latitude/longitude bounds
  if (( $(echo "$latitude < -90 || $latitude > 90" | bc -l) )); then
    echo "❌ Latitude out of range: $latitude"
    return 1
  fi
  if (( $(echo "$longitude < -180 || $longitude > 180" | bc -l) )); then
    echo "❌ Longitude out of range: $longitude"
    return 1
  fi

  # Validate unit (optional, if passed)
  if [[ -n "$unit" ]]; then
    case "$unit" in
      "Celsius"|"Fahrenheit"|"Kelvin") ;;
      *) echo "❌ Invalid unit: $unit (allowed: Celsius, Fahrenheit, Kelvin)"; return 1 ;;
    esac
  fi

  echo "✅ Inputs validated: $start_date to $end_date, lat=$latitude, lon=$longitude, unit=$unit"
  return 0
}

if [ ! -f $WEATHER_DB ]; then
	sqlite3 $WEATHER_DB "CREATE TABLE IF NOT EXISTS $WEATHER_TABLE (
		id INTEGER PRIMARY KEY
		,latitude REAL
		,longitude REAL
		,utc_offset_seconds INTEGER
		,elevation REAL
		,hourly_time TEXT
		,unit_time TEXT
		,timezone TEXT
		,hourly_temperature REAL
		,unit_temperature TEXT
		,hourly_surface_pressure REAL
		,unit_pressure TEXT
		,hourly_relative_humidity INTEGER
		,unit_relative_humidity TEXT
	)"

	sqlite3 $WEATHER_DB "CREATE INDEX id_latitude_longitude_time ON $WEATHER_TABLE (latitude, longitude, hourly_time); CREATE INDEX id_time on $WEATHER_TABLE (hourly_time)"

else
	START_DATE=\$(date -d "\${LAST_TIME:0:10} - 5 days" +%Y-%m-%d)
fi


getJson $START_DATE $END_DATE
jsonToCSV $WEATHER_JSON $WEATHER_CSV
loadDb $WEATHER_DB $WEATHER_CSV $WEATHER_TABL

