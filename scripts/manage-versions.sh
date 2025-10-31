#!/bin/bash

# Version Management Script for Docker Learning Documentation
# Helps compare, accept, or reject versioned file updates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Docker Learning - Version Management Tool${NC}"
echo ""

# Function to show help
show_help() {
    echo "Usage: ./scripts/manage-versions.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  list          List all versioned files (V*_)"
    echo "  compare FILE  Compare versioned file with current version"
    echo "  accept FILE   Accept versioned file (replaces current)"
    echo "  reject FILE   Reject versioned file (deletes it)"
    echo "  clean         Remove all versioned files"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/manage-versions.sh list"
    echo "  ./scripts/manage-versions.sh compare V2_quick-reference.md"
    echo "  ./scripts/manage-versions.sh accept V2_quick-reference.md"
    echo "  ./scripts/manage-versions.sh reject V2_quick-reference.md"
    echo "  ./scripts/manage-versions.sh clean"
}

# Function to list versioned files
list_versions() {
    echo -e "${YELLOW}Versioned files found:${NC}"
    echo ""
    
    found=0
    for file in $(find . -name "V[0-9]*_*" -type f); do
        echo "  📄 $file"
        found=1
    done
    
    if [ $found -eq 0 ]; then
        echo -e "${GREEN}  ✓ No versioned files found${NC}"
    fi
    echo ""
}

# Function to compare files
compare_files() {
    versioned_file=$1
    
    if [ ! -f "$versioned_file" ]; then
        echo -e "${RED}Error: File '$versioned_file' not found${NC}"
        exit 1
    fi
    
    # Extract original filename (remove V*_ prefix)
    original_file=$(echo "$versioned_file" | sed 's|.*/V[0-9]*_||')
    original_path=$(dirname "$versioned_file")/$original_file
    
    if [ ! -f "$original_path" ]; then
        echo -e "${YELLOW}Note: Original file '$original_path' doesn't exist${NC}"
        echo -e "${GREEN}This is a NEW file. Use 'accept' to add it.${NC}"
        echo ""
        echo "Preview of new file:"
        echo "-------------------"
        head -n 20 "$versioned_file"
        echo "..."
        return
    fi
    
    echo -e "${BLUE}Comparing:${NC}"
    echo "  Current:  $original_path"
    echo "  Updated:  $versioned_file"
    echo ""
    
    if diff -q "$original_path" "$versioned_file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Files are identical - no changes${NC}"
    else
        echo -e "${YELLOW}Differences found:${NC}"
        echo "-------------------"
        diff -u "$original_path" "$versioned_file" || true
    fi
    echo ""
}

# Function to accept versioned file
accept_file() {
    versioned_file=$1
    
    if [ ! -f "$versioned_file" ]; then
        echo -e "${RED}Error: File '$versioned_file' not found${NC}"
        exit 1
    fi
    
    # Extract original filename
    original_file=$(echo "$versioned_file" | sed 's|.*/V[0-9]*_||')
    original_path=$(dirname "$versioned_file")/$original_file
    
    if [ -f "$original_path" ]; then
        echo -e "${YELLOW}Replacing existing file:${NC} $original_path"
    else
        echo -e "${GREEN}Creating new file:${NC} $original_path"
    fi
    
    mv "$versioned_file" "$original_path"
    echo -e "${GREEN}✓ Accepted: $original_path${NC}"
    echo ""
}

# Function to reject versioned file
reject_file() {
    versioned_file=$1
    
    if [ ! -f "$versioned_file" ]; then
        echo -e "${RED}Error: File '$versioned_file' not found${NC}"
        exit 1
    fi
    
    rm "$versioned_file"
    echo -e "${RED}✗ Rejected and deleted: $versioned_file${NC}"
    echo ""
}

# Function to clean all versioned files
clean_versions() {
    echo -e "${YELLOW}Finding all versioned files...${NC}"
    echo ""
    
    found=0
    for file in $(find . -name "V[0-9]*_*" -type f); do
        echo "  🗑️  Removing: $file"
        rm "$file"
        found=1
    done
    
    if [ $found -eq 0 ]; then
        echo -e "${GREEN}  ✓ No versioned files to clean${NC}"
    else
        echo ""
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    fi
    echo ""
}

# Main script logic
case "${1:-help}" in
    list)
        list_versions
        ;;
    compare)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify a file to compare${NC}"
            echo "Usage: $0 compare V2_filename.md"
            exit 1
        fi
        compare_files "$2"
        ;;
    accept)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify a file to accept${NC}"
            echo "Usage: $0 accept V2_filename.md"
            exit 1
        fi
        accept_file "$2"
        ;;
    reject)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify a file to reject${NC}"
            echo "Usage: $0 reject V2_filename.md"
            exit 1
        fi
        reject_file "$2"
        ;;
    clean)
        clean_versions
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
