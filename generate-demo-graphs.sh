#!/bin/bash
#
rm *.pdf
NAME="lehman-yao-orthodox-btree"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="lehman-yao-orthodox-btree-suffix"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="lehman-yao-orthodox-btree-suffix-short"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="postgres-real-btree"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"

# Initial leaf page, about to be split
NAME="leaf-page-split"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"

# Unoptimized:
NAME="unoptimized-leaf-page-split-1"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="unoptimized-leaf-page-split-2"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="unoptimized-leaf-page-split-3"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
