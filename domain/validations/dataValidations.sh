#!/bin/bash

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
      "°C"|"°F"|"K"|"R"|"hPa"|"m"|"%") ;;
      *) echo "Invalid unit: $unit (allowed: Celsius, Fahrenheit, Kelvin, Rankin)"; return 1 ;;
    esac
  fi

  echo "Inputs validated: $start_date to $end_date, lat=$latitude, lon=$longitude, unit=$unit"
  return 0
}

