#!/bin/bash
set -e

# Script to generate golden reference hashes using ssdeep 2.14.1
# These hashes serve as the ground truth for compatibility testing
#
# Usage: ./Scripts/generate-golden-hashes.sh
# Requires: ssdeep 2.14.1 installed

echo "SSDeep Golden Hash Generator"
echo "============================"
echo ""

# Check if ssdeep is installed
if ! command -v ssdeep &> /dev/null; then
    echo "❌ Error: ssdeep command not found"
    echo "Please install ssdeep 2.14.1:"
    echo "  macOS: brew install ssdeep"
    echo "  Linux: apt-get install ssdeep"
    exit 1
fi

# Verify ssdeep version
SSDEEP_VERSION=$(ssdeep -V 2>&1 | head -n1)
echo "Found: $SSDEEP_VERSION"

if [[ ! "$SSDEEP_VERSION" =~ "2.14.1" ]]; then
    echo "⚠️  Warning: Expected ssdeep 2.14.1, found: $SSDEEP_VERSION"
    echo "Golden hashes may not match if using a different version"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

# Output file
OUTPUT_FILE="Tests/SSDeepTests/TestData/golden-hashes.txt"
TEMP_FILE=$(mktemp)

echo "Generating hashes for all test files..."
echo "# SSDeep Golden Reference Hashes" > "$TEMP_FILE"
echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> "$TEMP_FILE"
echo "# SSDeep Version: $SSDEEP_VERSION" >> "$TEMP_FILE"
echo "# Format: filepath|hash" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"

# Counter for progress
file_count=0

# Function to hash a file and add to output
hash_file() {
    local file="$1"
    local relative_path="${file#./}"

    # Get hash using ssdeep -b (bare mode - hash only, no filename)
    local hash=$(ssdeep -b "$file" 2>/dev/null | tail -n1 | cut -d',' -f1)

    if [ -n "$hash" ]; then
        echo "$relative_path|$hash" >> "$TEMP_FILE"
        file_count=$((file_count + 1))
        echo "  ✓ $relative_path"
    else
        echo "  ⚠️  Failed to hash: $relative_path"
    fi
}

# Hash all test files
echo ""
echo "Essential test vectors:"
for file in Tests/SSDeepTests/TestData/essential/*; do
    if [ -f "$file" ]; then
        hash_file "$file"
    fi
done

echo ""
echo "Real-world corpus:"
for file in Tests/SSDeepTests/TestData/real-world/*; do
    if [ -f "$file" ]; then
        hash_file "$file"
    fi
done

echo ""
echo "Generated test data:"
for file in Tests/SSDeepTests/TestData/generated/*; do
    if [ -f "$file" ]; then
        hash_file "$file"
    fi
done

# Move temp file to final location
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo ""
echo "============================"
echo "✅ Generated $file_count golden hashes"
echo "📄 Saved to: $OUTPUT_FILE"
echo ""
echo "⚠️  IMPORTANT: Only regenerate golden hashes when intentionally"
echo "   updating the algorithm. Never regenerate to 'fix' failing tests!"
