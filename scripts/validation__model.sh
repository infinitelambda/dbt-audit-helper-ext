#!/bin/bash

## To run a single model validation
## dbt_packages/audit_helper_ext/scripts/validation__model.sh -m sample_1

set -e

# Initialize the variables
MODEL=""
LOG_LOCATION=logs

# Parse command-line options
while getopts m:t:vr flag; do
    case "${flag}" in
        m) MODEL=${OPTARG};;
        t) VALIDATION_TYPE=${OPTARG};;
        r) SKIP_RUN=true;;
        v) SKIP_VALIDATION=true;;
        ?) echo "Invalid option: -${OPTARG}" >&2; exit 1;;
    esac
done

# Check if the variable is empty or doesn't exist
if [[ -z "$MODEL" ]]; then
    echo "Please add a valid model to the flag -m" >&2
    exit 1
fi

if [[ -z "$VALIDATION_TYPE" ]]; then
    VALIDATION_TYPE="all"
fi
VALIDATION_TYPE_UPPER=$(echo "$VALIDATION_TYPE" | tr '[:lower:]' '[:upper:]')


# Create the folder using mkdir -p
LOG_LOCATION_PIPE=$LOG_LOCATION/'validation__'$MODEL.log
mkdir -p "$LOG_LOCATION"

exec > >(tee -i $LOG_LOCATION_PIPE)
exec 2>&1

echo "📂  Log Location should be: [ $LOG_LOCATION_PIPE ]"

# Convert model name to lowercase
MODEL_lower=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')

macro_validation="validation_full__$MODEL_lower"
macro_validation_count="validation_count__$MODEL_lower"
macro_validation_col="validation_all_col__$MODEL_lower"


echo "🛫  Start the [ $VALIDATION_TYPE_UPPER ] validation(s) against [ $MODEL ]"
if [[ "$SKIP_RUN" != "true" ]]; then
    echo ''
    echo '🐑  Clone - '$MODEL' assuming that the source ('$MODEL_lower'__<YYYYMMDD>) exists in the same location of the target'
    set -x #echo on
    dbt run-operation clone_relation --args 'identifier: '$MODEL'' && \
    set +x #echo off`
    set +x #echo off`

    echo ''
    echo '▶️  Run  - '$MODEL''
    echo ''
    set -x #echo on
    dbt run -s +$MODEL --full-refresh --exclude $MODEL && \
    dbt run -s $MODEL && \
    set +x #echo off
    set +x #echo off
fi


if [[ "$SKIP_VALIDATION" != "true" ]]; then

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "COUNT" ]]; then
        echo ''
        echo '👀 🔢            Validate count - '$MODEL'                        👀'
        echo ''
        set -x #echo on
        dbt run-operation $macro_validation_count && \
        set +x #echo off
        set +x #echo off
    fi


    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "FULL" ]]; then
        echo ''
        echo '👀  ͍            Validate Row by row - Summarize True - '$MODEL'   👀'
        echo ''
        set -x #echo on
        dbt run-operation $macro_validation && \
        set +x #echo off

        echo ''
        echo '👀  ͍            Validate Row by row - Summarize False - '$MODEL'  👀'
        echo ''
        set -x #echo on
        dbt run-operation $macro_validation --args 'summarize: false' && \
        set +x #echo off
    fi


    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "ALL_COL" ]]; then
        echo ''
        echo '👀  ͍            Validate column by column - '$MODEL'              👀'
        echo ''
        set -x #echo on
        dbt run-operation $macro_validation_col && \
        set +x #echo off
    fi

fi
