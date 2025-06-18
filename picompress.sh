#!/bin/bash

# Parse arguments
if [ $# -lt 3 ] || [ "$2" != "-o" ]; then
    echo "Usage: $0 <input.png> -o <output.png>"
    echo "Example: $0 image.png -o compressed.png"
    exit 1
fi

INPUT="$1"
OUTPUT="$3"

# Check if input file exists
if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' not found!"
    exit 1
fi

# Check if input is a PNG file
if [[ ! "$INPUT" =~ \.png$ ]]; then
    echo "Error: Input file must be a PNG!"
    exit 1
fi

# Get original file size
ORIGINAL_SIZE=$(stat -c%s "$INPUT")

echo "Compressing '$INPUT'..."
echo "Original size: $(numfmt --to=iec-i --suffix=B $ORIGINAL_SIZE)"

# Step 1: pngquant (lossy compression)
echo "Step 1: Running pngquant..."
if ! pngquant --quality=65-80 "$INPUT" 2>/dev/null; then
    echo "Error: pngquant failed. Image might already be optimized or have issues."
    exit 1
fi

# pngquant creates a file with -fs8.png suffix by default
PNGQUANT_OUTPUT="${INPUT%.*}-fs8.png"

# Step 2: oxipng on the pngquant output
echo "Step 2: Running oxipng..."
if ! oxipng -o 2 --preserve "$PNGQUANT_OUTPUT" 2>/dev/null; then
    echo "Error: oxipng failed."
    rm -f "$PNGQUANT_OUTPUT"
    exit 1
fi

# Move the final result to desired output name
mv "$PNGQUANT_OUTPUT" "$OUTPUT"

# File cleanup is handled above

# Calculate compression ratio
FINAL_SIZE=$(stat -c%s "$OUTPUT")
COMPRESSION_RATIO=$(echo "scale=1; (1 - $FINAL_SIZE / $ORIGINAL_SIZE) * 100" | bc)

echo "✓ Compression complete!"
echo "Final size: $(numfmt --to=iec-i --suffix=B $FINAL_SIZE)"
echo "Compression: ${COMPRESSION_RATIO}%"
echo "Output: $OUTPUT"
