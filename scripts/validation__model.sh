#!/bin/bash

## To run and validate a model:
##      dbt_packages/audit_helper_ext/scripts/validation__model.sh -m sample_target_1
## To run only a model:
##      dbt_packages/audit_helper_ext/scripts/validation__model.sh -m sample_target_1 -v
## To validate only a model:
##      dbt_packages/audit_helper_ext/scripts/validation__model.sh -m sample_target_1 -r
## To validate only a model by type:
##      dbt_packages/audit_helper_ext/scripts/validation__model.sh -m sample_target_1 -r -t count | full | all_col | upstream_row_count

set -e

# Function to print the timestamp
timestamp() {
    date -u +"%H:%M:%S"
}

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
LOG_LOCATION=logs
LOG_LOCATION_PIPE=$LOG_LOCATION/'validation__'$MODEL.log
mkdir -p "$LOG_LOCATION"

exec > >(tee -i $LOG_LOCATION_PIPE)
exec 2>&1

echo "$(timestamp)  📂  Log Location should be: [ $LOG_LOCATION_PIPE ]"

# Convert model name to lowercase
MODEL_lower=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')
MODEL_UPPER=$(echo "$MODEL" | tr '[:lower:]' '[:upper:]')

macro_get_upstream_count="get_upstream_row_count"
macro_validation="validation_full__$MODEL_lower"
macro_validation_count="validation_count__$MODEL_lower"
macro_validation_all_col="validation_all_col__$MODEL_lower"


echo "$(timestamp)  🛫  Starting the [ $VALIDATION_TYPE_UPPER ] validation(s) against [ $MODEL_UPPER ] ..."
if [[ "$SKIP_RUN" != "true" ]]; then
    echo "$(timestamp)  "
    echo "$(timestamp)  🐑  Clone - $MODEL_UPPER assuming that the source (schema___<YYYYMMDD>.$MODEL_UPPER) exists"
    set -x #echo on
    dbt run-operation clone_relation --args {'identifier: '$MODEL'}' && \
    set +x #echo off`
    set +x #echo off`

    echo "$(timestamp)  "
    echo "$(timestamp)  ▶️  Run  - $MODEL_UPPER"
    echo "$(timestamp)  "
    set -x #echo on
    dbt run -s +$MODEL --full-refresh --exclude $MODEL && \
    dbt run -s $MODEL && \
    set +x #echo off
    set +x #echo off
fi


if [[ "$SKIP_VALIDATION" != "true" ]]; then

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "UPSTREAM_ROW_COUNT" ]]; then
        echo "$(timestamp)  "
        echo "$(timestamp)  👀 🔢            Get upstream row counts - $MODEL_UPPER                      👀"
        echo "$(timestamp)  "
        set -x #echo on
        dbt run-operation $macro_get_upstream_count --args {'dbt_identifier: '$MODEL'}'  && \
        set +x #echo off
        set +x #echo off
    fi

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "COUNT" ]]; then
        echo "$(timestamp)  "
        echo "$(timestamp)  👀 🔢            Validate count - $MODEL_UPPER                        👀"
        echo "$(timestamp)  "
        set -x #echo on
        dbt run-operation $macro_validation_count && \
        set +x #echo off
        set +x #echo off
    fi


    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "FULL" ]]; then
        echo "$(timestamp)  "
        echo "$(timestamp)  👀  ͍            Validate Row by row - Summarize True - $MODEL_UPPER   👀"
        echo "$(timestamp)  "
        set -x #echo on
        dbt run-operation $macro_validation && \
        set +x #echo off
        set +x #echo off

        echo "$(timestamp)  "
        echo "$(timestamp)  👀  ͍            Validate Row by row - Summarize False - $MODEL_UPPER  👀"
        echo "$(timestamp)  "
        set -x #echo on
        dbt run-operation $macro_validation --args {'summarize: false'} && \
        set +x #echo off
        set +x #echo off
    fi


    if [[ "$VALIDATION_TYPE_UPPER" == "ALL_COL" ]]; then # Useful for debugging purpose only
        echo "$(timestamp)  "
        echo "$(timestamp)  👀  ͍            Validate column by column - $MODEL_UPPER              👀"
        echo "$(timestamp)  "
        set -x #echo on
        dbt run-operation $macro_validation_all_col && \
        set +x #echo off
        set +x #echo off
    fi

fi
