# sqlite-utils.sh

DB_FILE="db_weather.db"   # or pass this in dynamically

# Run a SELECT and print results as TSV (easy to parse)
db_get() {
  local sql="$1"
  shift
  sqlite3 -tabs "$DB_FILE" "$sql" "$@"
}

# Run any SQL (INSERT, UPDATE, DELETE, CREATE, etc.)
db_exec() {
  local sql="$1"
  shift
  sqlite3 "$DB_FILE" "$sql" "$@"
}
