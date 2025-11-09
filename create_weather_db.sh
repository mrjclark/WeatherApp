#!/bin/bash

set -eou

trap "Error at line $LINENO"

DB_INIT=false

if [ ! -f "db_weather.db" ]; then
	sqlite3 db_weather.db
	DB_INIT=true
fi


