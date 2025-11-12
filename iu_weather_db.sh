#!/bin/bash

set -eou pipefail

# sudo apt update && sudo install sqlie3 jq -y

START_DATE="2020-01-01" # This is the defualt for if the DB doesn't exist
END_DATE=$(date +%Y-%m-%d)
WEATHER_DB="db_weather.db"
WEATHER_TABLE="weather"
WEATHER_JSON="weather-info.json"
WEATHER_CSV="weather-info.csv"
UPDATE_FILE="update_weather_db.sh"
LAT_FIELD=29.3522 
LON_FIELD=-95.4602
TZ_FIELD="America/Chicago"
DATA_FIELDS="temperature_2m,surface_pressure,relative_humidity_2m"

trap "Error at line ${LINENO}" ERR


# infer_type: Returns symbolic type label for a given input
infer_type() {
  local value="$1"

  if [[ -z "$value" ]]; then
    echo "empty"
  elif [[ "$value" == "true" || "$value" == "false" ]]; then
    echo "BOOLEAN"
  elif [[ "$value" =~ ^-?[0-9]+$ ]]; then
    echo "INTEGER"
  elif [[ "$value" =~ ^-?[0-9]+\.[0-9]+$ ]]; then
    echo "REAL"
  elif [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "TEXT"
  else
    echo "TEXT"
  fi
}

function getJson() {
	API_URL="https://archive-api.open-meteo.com/v1/archive?latitude=$1&longitude=$2&start_date=$3&end_date=$4&hourly=$5&timezone=$6"
	curl $API_URL > $7
	echo $API_URL
}

function getJsonFields() {
	if [[ -z $2 ]]; then
		echo $(jq "keys" $1)
	else
		echo $(jq "$2 | keys")
	fi
}

function createTableFromJson() {
	
	sqlite3 $1 "CREATE TABLE IF NOT EXISTS $2 (
		id TEXT PRIMARY KEY
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

	sqlite3 $1 "CREATE INDEX id_latitude_longitude_time ON $2 (latitude, longitude, hourly_time); CREATE INDEX id_time on $2 (hourly_time)"

}

function createCSV() {
	sqlite3 $1 "PRAGMA table_info($2);" | awk -F'|' '{print $2}' | paste -sd',' - >$3
}

function jsonToCsv() {
	
	jq -r '
	  . as $root |
	  [range(0; $root.hourly.time | length)][] as $i |
	  [
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

# log function: Ensures logging at different levels, as well as custom logging.
function logEvent() {
	echo "$(date -Isecond) | $1 | $2" >> weatherApp.log
}

function logError() {
	logEvent "ERROR" $1
}

function logWarning() {
	logEvent "WARNING" $1
}

function logInfo() {
	logEvent "INFO" $1
}

function logDebug() {
	logEvent "DEBUG" $1
}

# validate_inputs: Ensures all inputs are correctly formatted and within allowed ranges
function validateInputs() {
  local start_date="$1"
  local end_date="$2"
  local latitude="$3"
  local longitude="$4"
  local unit="$5"

  # Validate date format YYYY-MM-DD
  for date in "$start_date" "$end_date"; do
    if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "Invalid date format: $date (expected YYYY-MM-DD)"
      return 1
    fi
  done

  # Validate numeric latitude and longitude
  for coord in "$latitude" "$longitude"; do
    if [[ ! "$coord" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
      echo "Invalid coordinate: $coord (expected numeric)"
      return 1
    fi
  done

  # Validate latitude/longitude bounds
  if (( $(echo "$latitude < -90 || $latitude > 90" | bc -l) )); then
    echo "Latitude out of range: $latitude"
    return 1
  fi
  if (( $(echo "$longitude < -180 || $longitude > 180" | bc -l) )); then
    echo "Longitude out of range: $longitude"
    return 1
  fi

  # Validate unit (optional, if passed)
  if [[ -n "$unit" ]]; then
    case "$unit" in
      "Celsius"|"Fahrenheit"|"Kelvin") ;;
      *) echo "Invalid unit: $unit (allowed: Celsius, Fahrenheit, Kelvin)"; return 1 ;;
    esac
  fi

  echo "Inputs validated: $start_date to $end_date, lat=$latitude, lon=$longitude, unit=$unit"
  return 0
}

if [ ! -f $WEATHER_DB ]; then
	getJson $LAT_FIELD $LON_FIELD $END_DATE $END_DATE $DATA_FIELDS $TZ_FIELD $WEATHER_JSON 
	createTableFromJson $WEATHER_DB $WEATHER_TABLE
else
	LAST_TIME=$(sqlite3 $WEATHER_DB "SELECT MAX(hourly_time) FROM $WEATHER_TABLE")
	START_DATE=$(date -d "${LAST_TIME:0:10} - 5 days" +%Y-%m-%d)
fi 


getJson $LAT_FIELD $LON_FIELD $START_DATE $END_DATE $DATA_FIELDS $TZ_FIELD $WEATHER_JSON 
jsonToCsv $WEATHER_JSON $WEATHER_CSV
loadDb $WEATHER_DB $WEATHER_CSV $WEATHER_TABLE

