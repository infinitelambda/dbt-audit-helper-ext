#!/bin/bash

## To run a single model validation
## dbt_packages/audit_helper_ext/scripts/validation__model.sh -m sample_1

set -e

# Initialize the variables
MODEL=""
LOG_LOCATION=logs

# Parse command-line options
while getopts m: flag; do
    case "${flag}" in
        m) MODEL=${OPTARG};;
        ?) echo "Invalid option: -${OPTARG}" >&2; exit 1;;
    esac
done

# Check if the MODEL variable is empty or doesn't exist
if [[ -z "$MODEL" ]]; then
    echo "Please add a valid model to the flag -m" >&2
    exit 1
fi


LOG_LOCATION_PIPE=$LOG_LOCATION/'validation__'$MODEL.log

# Create the folder using mkdir -p
mkdir -p "$LOG_LOCATION"

exec > >(tee -i $LOG_LOCATION_PIPE)
exec 2>&1

echo "📂  Log Location should be: [ $LOG_LOCATION_PIPE ]"

# Convert model name to lowercase
MODEL_lower=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')

macro_validation="validation_full__$MODEL_lower"
macro_validation_count="validation_count__$MODEL_lower"
macro_validation_col="validation_all_col__$MODEL_lower"

echo ''
echo '                     🐑  Clone - '$MODEL''
set -x #echo on
dbt run-operation clone --args 'table_to_clone: '$MODEL'' && \
set +x #echo off`
set +x #echo off`

echo ''
echo '                      ▶️  Run '$MODEL''
echo ''
set -x #echo on
dbt run -s +$MODEL --full-refresh && \
set +x #echo off
set +x #echo off

echo ''
echo '👀 🔢            Validate count - '$MODEL'          👀'
echo ''
set -x #echo on
dbt run-operation $macro_validation_count && \
set +x #echo off
set +x #echo off

echo ''
echo '👀  ͍            Validate Row by row - Summarize True - '$MODEL'          👀'
echo ''
set -x #echo on
dbt run-operation $macro_validation && \
set +x #echo off


echo ''
echo '👀  ͍            Validate Row by row - Summarize False - '$MODEL'          👀'
echo ''
set -x #echo on
dbt run-operation $macro_validation --args 'summarize: false' && \
set +x #echo off



echo ''
echo '👀  ͍            Validate column by column - '$MODEL'          👀'
echo ''
set -x #echo on
dbt run-operation $macro_validation_col && \
set +x #echo off
