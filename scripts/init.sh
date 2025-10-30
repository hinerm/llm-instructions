#!/bin/bash

# init.sh - Generate LLM instruction files for projects

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    cat << EOF
Usage: $0 <target_project_path> <environment> <file_lists...>

Generate LLM instruction files for projects by merging markdown files.

Arguments:
  target_project_path  Path to the target project root where instructions will be created
  environment          Output environment - either 'copilot' or 'claude'
                       - copilot: creates .github/copilot-instructions.md
                       - claude: creates .clauderc
  file_lists           One or more lists of markdown files to merge
                       Format: [directory:]file1,file2,file3
                       - Directory defaults to 'copilot' if not specified
                       - .md extension is optional
                       - Multiple lists can be space-separated

Examples:
  # Basic SciJava project
  $0 ~/my-project copilot scijava-foundation,scijava-common

  # ImageJ2 algorithm development
  $0 ~/my-project copilot scijava-foundation,imglib2,imagej-common,imagej-ops

  # Multiple file lists
  $0 ~/my-project copilot copilot:scijava-foundation,imglib2 copilot:imagej-common

  # For Claude Code
  $0 ~/my-project claude scijava-foundation,scijava-common
EOF
    exit 1
}

# Function to print error messages
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    echo ""
    usage
}

# Function to print success messages
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print info messages
info() {
    echo -e "${YELLOW}$1${NC}"
}

# Check arguments
if [ $# -lt 3 ]; then
    usage
fi

TARGET_PATH="$1"
ENVIRONMENT="$2"
shift 2
FILE_LISTS=("$@")

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Validate environment
if [[ "$ENVIRONMENT" != "copilot" && "$ENVIRONMENT" != "claude" ]]; then
    error "Environment must be 'copilot' or 'claude', got: $ENVIRONMENT"
fi

# Validate target path
if [ ! -d "$TARGET_PATH" ]; then
    error "Target path does not exist: $TARGET_PATH"
fi

# Determine output file based on environment
if [ "$ENVIRONMENT" == "copilot" ]; then
    OUTPUT_DIR="$TARGET_PATH/.github"
    OUTPUT_FILE="$OUTPUT_DIR/copilot-instructions.md"
else
    OUTPUT_FILE="$TARGET_PATH/.clauderc"
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR"

info "Generating $ENVIRONMENT instructions at: $OUTPUT_FILE"
echo ""

# Track whether we found any files
FOUND_ANY_FILES=false

# Create a temporary file to collect content
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Process each file list
for FILE_LIST in "${FILE_LISTS[@]}"; do
    # Check if the list has a directory prefix
    if [[ "$FILE_LIST" == *:* ]]; then
        DIR="${FILE_LIST%%:*}"
        FILES="${FILE_LIST#*:}"
    else
        # Default to copilot directory
        DIR="copilot"
        FILES="$FILE_LIST"
    fi
    
    # Split files by comma
    IFS=',' read -ra FILE_ARRAY <<< "$FILES"
    
    for FILE in "${FILE_ARRAY[@]}"; do
        # Trim whitespace
        FILE="$(echo "$FILE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        
        # Add .md extension if not present
        if [[ "$FILE" != *.md ]]; then
            FILE="$FILE.md"
        fi
        
        # Construct full path
        FULL_PATH="$REPO_ROOT/$DIR/$FILE"
        
        # Check if file exists
        if [ ! -f "$FULL_PATH" ]; then
            error "File not found: $FULL_PATH"
        fi
        
        # Mark that we found at least one file
        FOUND_ANY_FILES=true
        
        info "  Adding: $DIR/$FILE"
        
        # Append file contents to temp file
        cat "$FULL_PATH" >> "$TEMP_FILE"
        
        # Add a newline between files for separation
        echo "" >> "$TEMP_FILE"
    done
done

echo ""

# Only create the output file if we found any instruction files
if [ "$FOUND_ANY_FILES" = true ]; then
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    success "✓ Successfully created $ENVIRONMENT instructions!"
    success "  Output: $OUTPUT_FILE"
    success "  Files merged: $(grep -c '^' "$OUTPUT_FILE") lines"
else
    error "No instruction files were found. Output file not created."
fi
