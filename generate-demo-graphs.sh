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

# no optimized
NAME="no-optimized-left-leaf-page-split"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="no-optimized-right-leaf-page-split"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="no-optimized-right-leaf-page-split-next"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="no-optimized-right-leaf-page-split-next-next"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"

# optimized
NAME="optimized-left-leaf-page-split"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="optimized-right-leaf-page-split"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="optimized-left-leaf-page-split-next"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
NAME="optimized-left-leaf-page-split-next-next"
echo "Generating __$NAME.pdf..."
dot -T pdf "$NAME.dot" -o "__$NAME.pdf"
