#!/usr/bin/env bash
set -euo pipefail


START_DATE=""
END_DATE=""
LOCATION=""
TIMEZONE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --start-date=*)
            START_DATE="${1#*=}"
            shift
            ;;
        --start-date)
            START_DATE="$2"
            shift 2
            ;;
        --end-date=*)
            END_DATE="${1#*=}"
            shift
            ;;
        --end-date)
            END_DATE="$2"
            shift 2
            ;;
        --location=*)
            LOCATION="${1#*=}"
            shift
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --timezone=*)
            TIMEZONE="${1#*=}"
            shift
            ;;
        --timezone)
            TIMEZONE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --start-date YYYY-MM-DD --end-date YYYY-MM-DD --location <##.####,##.####> --TIMEZONE <Country/City>"
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

[[ -z "$START_DATE" ]] && echo "Missing flag: --start-date, using default" 
[[ -z "$END_DATE" ]] && echo "Missing flag: --end-date, using default"
[[ -z "$LOCATION" ]] && { echo "Missing required flag: --location"; exit 1; }
[[ -z "$TIMEZONE" ]] && echo "Missing flag: --timezone; using default"

START_DATE=$(bash validateInputViewModel.sh start-date)
END_DATE=$(bash validateInputViewModel.sh end-date)
LOCATION=$(bash validateInputViewModel.sh location)
TIMEZONE=$(bash validateInputViewModel.sh timezone)

echo "Start date: $START_DATE"
echo "End date:   $END_DATE"
echo "Location:   $LOCATION"
echo "Timezone:   $TIMEZONE"

