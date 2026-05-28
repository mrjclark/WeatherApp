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


