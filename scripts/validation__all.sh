#!/bin/bash

set -e
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

# Help function
show_help() {
    cat << EOF
dbt Audit Helper Validation Script

DESCRIPTION:
    Run comprehensive data validation for dbt mart models using the audit helper 
    extension. Compares current dbt model outputs against legacy mart data to 
    ensure data consistency during migration.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h          Show this help message and exit
    -t TYPE     Validation type (default: all)
                  all                - Run all validation types
                  count              - Row count validation only
                  schema             - Schema/column comparison validation
                  all_row            - Row-by-row validation
                  all_col            - Column-by-column validation (debug)
                  upstream_row_count - Get upstream source counts
    -d DIR      Models directory path (default: models/03_mart)
                Can target any dbt model directory
    -m MODEL    Single model name to validate (if not specified, validates all models)
                Example: -m exp_fsr_rol_plyr_anchr_id
    -p DATE     Audit helper date of process (e.g., "2024-01-01")
                When specified, triggers clone operations from legacy data
                When empty/omitted, skips cloning and runs with full-refresh
    -c RUNNER   Command runner to use (default: venv)
                  venv     - Use activated virtual environment (no wrapper)
                  poetry   - Use 'poetry run' for commands
                  uv       - Use 'uv run' for commands
    -r          Skip model runs, validate only
                Useful when models are already built and you only want validation
    -v          Run models only, skip validation
                Useful for building models without running time-consuming validations

EXAMPLES:
    # Run all validations with default settings
    $0

    # Run specific validation types
    $0 -t count                                # Count validation only
    $0 -t schema                               # Schema validation only
    $0 -t all_row                              # Row-by-row validation
    $0 -t upstream_row_count                   # Get source row counts

    # Target different model directories
    $0 -d models/02_intermediate               # Validate intermediate models
    $0 -d models/01_staging                    # Validate staging models

    # Single model validation
    $0 -m exp_fsr_rol_plyr_anchr_id           # All validations for one model
    $0 -m exp_fsr_rol_plyr_anchr_id -t count  # Count validation for one model
    $0 -m exp_fsr_rol_plyr_anchr_id -r        # Skip runs, validate one model only

    # Use with different command runners
    $0                                        # Use venv (default - requires activated environment)
    $0 -c poetry                              # Explicitly use poetry run
    $0 -c uv -t count                         # Use uv run

    # Use with audit date (triggers clone operations)
    $0 -p "2024-01-01"                        # Clone from specific date
    $0 -p "2024-01-01" -t count               # Clone + count validation

    # Skip operations for faster execution
    $0 -t count -r                            # Count validation only, skip model runs
    $0 -v                                     # Build models only, skip validation

    # Complex combinations
    $0 -d models/03_mart -t all_row -p "2024-01-01" -r   # Row validation with clone, skip runs
    $0 -c poetry -d models/03_mart -t count   # Use poetry run for count validation

VALIDATION TYPES:
    count               Fast row count comparison between models and legacy data
    schema              Schema and column structure comparison between models
    all_row             Detailed row-by-row comparison with summarized results
    all_col             Column-by-column validation for debugging data differences
    upstream_row_count  Check source table row counts before validation
    all                 Run all validation types above (except all_col)

LOGGING:
    Individual model logs: logs/validation__<model>.log
    Each model gets one log file containing all validation operations
    All validation types (count, all_row, etc.) append to the same model log
EOF
}

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Function to print the timestamp
timestamp() {
    date -u +"%H:%M:%S"
}

# Colored logging functions
log_info() {
    echo -e "${BLUE}$(timestamp)  $1${NC}"
}

log_success() {
    echo -e "${GREEN}$(timestamp)  $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}$(timestamp)  $1${NC}"
}

log_error() {
    echo -e "${RED}$(timestamp)  $1${NC}"
}

log_header() {
    echo -e "${PURPLE}$(timestamp)  $1${NC}"
}

log_operation() {
    echo -e "${CYAN}$(timestamp)  $1${NC}"
}

# Validation functions
validate_dependencies() {
    local missing_deps=()

    # Check for the configured command runner
    if [[ "$COMMAND_RUNNER" == "poetry" ]]; then
        command -v poetry >/dev/null 2>&1 || missing_deps+=("poetry")
    elif [[ "$COMMAND_RUNNER" == "uv" ]]; then
        command -v uv >/dev/null 2>&1 || missing_deps+=("uv")
    elif [[ "$COMMAND_RUNNER" == "venv" ]]; then
        # For venv, check if dbt is available in the current environment
        command -v dbt >/dev/null 2>&1 || {
            log_error "dbt command not found in current environment"
            log_error "Please activate your virtual environment first:"
            log_error "  source .venv/bin/activate  # Linux/macOS"
            log_error "  .venv\\Scripts\\activate    # Windows"
            exit 1
        }
    else
        log_error "Invalid command runner: $COMMAND_RUNNER"
        log_error "Valid options: poetry, uv, venv"
        exit 1
    fi

    # Check for other required commands
    command -v find >/dev/null 2>&1 || missing_deps+=("find")
    command -v sort >/dev/null 2>&1 || missing_deps+=("sort")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install missing dependencies and try again."
        exit 1
    fi
}

validate_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_error "Directory does not exist: $dir"
        exit 1
    fi
}

validate_validation_type() {
    local type="$1"
    local valid_types=("all" "count" "schema" "all_row" "all_col" "upstream_row_count")
    
    for valid_type in "${valid_types[@]}"; do
        if [[ "$type" == "$valid_type" ]]; then
            return 0
        fi
    done
    
    log_error "Invalid validation type: $type"
    log_error "Valid types: ${valid_types[*]}"
    exit 1
}

# Unified function to run operations for all models
run_operation_for_all_models() {
    local operation_type="$1"
    local operation_name="${2:-$operation_type}"
    local macro_name="$3"
    local args="$4"
    local model_suffix="$5"  # If set, appends to macro name (e.g., "__$model")
    
    local total=${#MODELS[@]}
    local current=0
    
    echo ""
    log_header "👀 📊            $operation_name - ($total) model(s)                    👀"
    echo ""
    
    for model in "${MODELS[@]}"; do
        ((current++))
        log_operation "🔍  [$current/$total] $operation_type: $model"
        
        # Use single log file per model (append all operations to same file)
        local model_log="$LOG_LOCATION/validation__${model}.log"
        
        local macro_call
        local cmd_args
        if [[ -n "$model_suffix" && "$model_suffix" == "true" ]]; then
            macro_call="${macro_name}__$model"
            if [[ -n "$args" ]]; then
                cmd_args="$args"
            else
                cmd_args=""
            fi
        else
            macro_call="$macro_name"
            if [[ -n "$args" ]]; then
                cmd_args="{'dbt_identifier': '$model', $args}"
            else
                cmd_args="{'dbt_identifier': '$model'}"
            fi
        fi
        
        # Run the operation and capture output to model-specific log (append mode)
        {
            if [[ -n "$cmd_args" && "$cmd_args" != "" ]]; then
                if [[ -n "$DATE_OF_PROCESS" && "$DATE_OF_PROCESS" != "" ]]; then
                    log_operation "Executing: $RUN_CMD dbt run-operation $macro_call --args '$cmd_args' ($DATE_OF_PROCESS) $DBT_ARGS"
                    $RUN_CMD dbt run-operation "$macro_call" --args "$cmd_args" --vars "{'audit_helper__date_of_process': '$DATE_OF_PROCESS'}" $DBT_ARGS
                else
                    log_operation "Executing: $RUN_CMD dbt run-operation $macro_call --args '$cmd_args' $DBT_ARGS"
                    $RUN_CMD dbt run-operation "$macro_call" --args "$cmd_args" $DBT_ARGS
                fi
            else
                if [[ -n "$DATE_OF_PROCESS" && "$DATE_OF_PROCESS" != "" ]]; then
                    log_operation "Executing: $RUN_CMD dbt run-operation $macro_call ($DATE_OF_PROCESS) $DBT_ARGS"
                    $RUN_CMD dbt run-operation "$macro_call" --vars "{'audit_helper__date_of_process': '$DATE_OF_PROCESS'}" $DBT_ARGS
                else
                    log_operation "Executing: $RUN_CMD dbt run-operation $macro_call $DBT_ARGS"
                    $RUN_CMD dbt run-operation "$macro_call" $DBT_ARGS
                fi
            fi

            local exit_code=$?
            echo ""

        } 2>&1 | tee -a "$model_log" || {
            log_error "$operation_type failed for $model, continuing..."
            echo "ERROR: $operation_type failed for $model at $(date)" >> "$model_log"
        }
    done
    
    # Show model log locations once per validation type
    echo ""
}

# Function to run clone operations for models
run_clone_for_all_models() {
    if [[ -n "$SINGLE_MODEL" ]]; then
        log_info "🐑  Clone relation for single model: $SINGLE_MODEL from PREVIOUS data version of $DATE_OF_PROCESS"
        log_operation "🐑  Cloning: $SINGLE_MODEL"

        set -x #echo on
        $RUN_CMD dbt run-operation clone_relation --args "{'identifier': '$SINGLE_MODEL', 'use_prev': true}" --vars "{'audit_helper__date_of_process': '$DATE_OF_PROCESS'}" $DBT_ARGS || { log_error "Clone failed for $SINGLE_MODEL"; exit 1; }
        set +x #echo off
    else
        log_info "🐑  Clone all relations from PREVIOUS data version of $DATE_OF_PROCESS"
        for model in "${MODELS[@]}"; do
            log_operation "🐑  Cloning: $model"

            set -x #echo on
            $RUN_CMD dbt run-operation clone_relation --args "{'identifier': '$model', 'use_prev': true}" --vars "{'audit_helper__date_of_process': '$DATE_OF_PROCESS'}" $DBT_ARGS || { log_error "Clone failed for $model"; exit 1; }
            set +x #echo off
        done
    fi
}

# Parse command-line options
while getopts ht:d:m:p:c:vr flag; do
    case "${flag}" in
        h) show_help; exit 0;;
        t) VALIDATION_TYPE=${OPTARG};;
        d) MART_DIR=${OPTARG};;
        m) SINGLE_MODEL=${OPTARG};;
        p) DATE_OF_PROCESS=${OPTARG};;
        c) COMMAND_RUNNER=${OPTARG};;
        r) SKIP_RUN=true;;
        v) SKIP_VALIDATION=true;;
        ?) echo "Use -h for help" >&2; exit 1;;
    esac
done

# Set defaults
VALIDATION_TYPE="${VALIDATION_TYPE:-all}"
MART_DIR="${MART_DIR:-models/03_mart}"
SINGLE_MODEL="${SINGLE_MODEL:-}"
DATE_OF_PROCESS="${DATE_OF_PROCESS:-}"
COMMAND_RUNNER="${COMMAND_RUNNER:-venv}"
SKIP_RUN="${SKIP_RUN:-false}"
SKIP_VALIDATION="${SKIP_VALIDATION:-false}"

# Set the run command based on the runner
if [[ "$COMMAND_RUNNER" == "poetry" ]]; then
    RUN_CMD="poetry run"
elif [[ "$COMMAND_RUNNER" == "uv" ]]; then
    RUN_CMD="uv run"
else
    # venv - no wrapper needed, commands run directly
    RUN_CMD=""
fi

# Build DBT arguments from environment variables
DBT_ARGS=""
if [[ -n "${DBT_PROFILES_DIR:-}" ]]; then
    DBT_ARGS="$DBT_ARGS --profiles-dir $DBT_PROFILES_DIR"
fi
if [[ -n "${DBT_PROJECT_DIR:-}" ]]; then
    DBT_ARGS="$DBT_ARGS --project-dir $DBT_PROJECT_DIR"
fi
if [[ -n "${DBT_TARGET:-}" ]]; then
    DBT_ARGS="$DBT_ARGS --target $DBT_TARGET"
fi

# Validate dependencies after setting COMMAND_RUNNER
validate_dependencies

# Log the command runner being used
if [[ "$COMMAND_RUNNER" == "venv" ]]; then
    log_info "🐍  Using activated virtual environment (no wrapper)"
else
    log_info "🐍  Using command runner: $COMMAND_RUNNER"
fi

# Validate configuration
validate_validation_type "$VALIDATION_TYPE"
validate_directory "$MART_DIR"

VALIDATION_TYPE_UPPER=$(echo "$VALIDATION_TYPE" | tr '[:lower:]' '[:upper:]')

# Prevent both skip flags being set
if [[ "$SKIP_RUN" == "true" && "$SKIP_VALIDATION" == "true" ]]; then
    log_error "Cannot skip both model runs and validation. Nothing would be executed."
    exit 1
fi

# Dynamically get models from the specified directory or use single model
MODELS=()
if [[ -n "$SINGLE_MODEL" ]]; then
    # Search for the model file recursively within MART_DIR
    model_file=$(find "$MART_DIR" -name "$SINGLE_MODEL.sql" -type f | head -1)

    if [[ -z "$model_file" || ! -f "$model_file" ]]; then
        log_error "Model file does not exist: $SINGLE_MODEL.sql in $MART_DIR/"
        log_error "Available models in $MART_DIR/:"
        find "$MART_DIR" -name "*.sql" -type f -exec basename {} .sql \; | sort
        exit 1
    fi
    MODELS=("$SINGLE_MODEL")
    log_info "📋  Validating single model: $SINGLE_MODEL"
    log_info "    Located at: $model_file"
else
    # Get all models from the directory
    while IFS= read -r -d '' file; do
        model_name=$(basename "$file" .sql)
        MODELS+=("$model_name")
    done < <(find "$MART_DIR" -name "*.sql" -type f -print0 | sort -z)
    
    log_info "📋  Found ${#MODELS[@]} models in $MART_DIR/:"
    for model in "${MODELS[@]}"; do
        log_info "    - $model"
    done
fi

# Create the logs directory and set up logging
LOG_LOCATION=logs
mkdir -p "$LOG_LOCATION"

# Initialize individual model log files
for model in "${MODELS[@]}"; do
    model_log="$LOG_LOCATION/validation__${model}.log"
    {
        echo "=========================================="
        echo "VALIDATION LOG FOR MODEL: $model"
        echo "=========================================="
        echo "Execution started: $(date)"
        echo "Validation types: $VALIDATION_TYPE_UPPER"
        echo "=========================================="
        echo ""
    } > "$model_log"
done

if [[ -n "$SINGLE_MODEL" ]]; then
    log_header "🛫  Starting [ $VALIDATION_TYPE_UPPER ] validation(s) for model: $SINGLE_MODEL..."
else
    log_header "🛫  Starting [ $VALIDATION_TYPE_UPPER ] validation(s) for ALL mart models..."
fi

# Run all models first if not skipped
if [[ "$SKIP_RUN" != "true" ]]; then
    echo ""
    log_info "🔍  Checking DATE_OF_PROCESS parameter..."
    
    if [[ -z "$DATE_OF_PROCESS" || "$DATE_OF_PROCESS" == "fresh" || "$DATE_OF_PROCESS" == "empty" ]]; then
        log_warning "📅  DATE_OF_PROCESS is empty/fresh/not configured"
        log_warning "⏭️   Skipping clone operations"
        echo ""
        if [[ -n "$SINGLE_MODEL" ]]; then
            log_header "▶️  Run single model: $SINGLE_MODEL (with full-refresh)"
            echo ""
            set -x #echo on
            $RUN_CMD dbt run -s +"$SINGLE_MODEL" --full-refresh $DBT_ARGS
            set +x #echo off
        else
            log_header "▶️  Run all models (with full-refresh)"
            echo ""
            set -x #echo on
            $RUN_CMD dbt run -s +"$MART_DIR/" --full-refresh $DBT_ARGS
            set +x #echo off
        fi
    else
        log_success "📅  DATE_OF_PROCESS is configured: $DATE_OF_PROCESS"
        echo ""
        run_clone_for_all_models

        echo ""
        if [[ -n "$SINGLE_MODEL" ]]; then
            log_header "▶️  Run single model: $SINGLE_MODEL (without full-refresh)"
            echo ""
            set -x #echo on
            $RUN_CMD dbt run -s +"$SINGLE_MODEL" --vars "{'audit_helper__date_of_process': '$DATE_OF_PROCESS'}" $DBT_ARGS
            set +x #echo off
        else
            log_header "▶️  Run all models (without full-refresh)"
            echo ""
            set -x #echo on
            $RUN_CMD dbt run -s +"$MART_DIR/" --vars "{'audit_helper__date_of_process': '$DATE_OF_PROCESS'}" $DBT_ARGS
            set +x #echo off
        fi
    fi
fi

# Run validations if not skipped
if [[ "$SKIP_VALIDATION" != "true" ]]; then

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "UPSTREAM_ROW_COUNT" ]]; then
        run_operation_for_all_models "Getting upstream count" "Get upstream row counts" "get_upstream_row_count" "" ""
    fi

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "COUNT" ]]; then
        run_operation_for_all_models "Count validation" "Validate count" "validation_count" "" "true"
    fi

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "SCHEMA" ]]; then
        run_operation_for_all_models "Schema validation" "Validate schema" "validation_schema" "" "true"
    fi

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL" || "$VALIDATION_TYPE_UPPER" == "ALL_ROW" ]]; then
        run_operation_for_all_models "Row validation (summarize=true)" "Validate Row by row - Summarize True" "validation_full" "" "true"
        run_operation_for_all_models "Row validation (summarize=false)" "Validate Row by row - Summarize False" "validation_full" "{'summarize': false}" "true"
    fi

    if [[ "$VALIDATION_TYPE_UPPER" == "ALL_COL" ]]; then # Useful for debugging purpose only
        run_operation_for_all_models "Column validation" "Validate column by column" "validation_all_col" "" "true"
    fi

fi

echo ""
if [[ -n "$SINGLE_MODEL" ]]; then
    log_success "✅  Completed [ $VALIDATION_TYPE_UPPER ] validation(s) for model: $SINGLE_MODEL!"
    log_info "📂  Model log: [ $LOG_LOCATION/validation__$SINGLE_MODEL.log ]"
else
    log_success "✅  Completed [ $VALIDATION_TYPE_UPPER ] validation(s) for ALL mart models!"
    log_info "📂  Total log files created: $(find "$LOG_LOCATION" -name "validation__*.log" | wc -l | tr -d ' ') model logs"
fi