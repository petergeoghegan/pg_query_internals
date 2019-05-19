#!/bin/bash
#
rm *.pdf
NAME="lehman-yao-orthodox-btree"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
NAME="lehman-yao-orthodox-btree-suffix"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
NAME="lehman-yao-orthodox-btree-suffix-short"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
NAME="postgres-real-btree"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"

# Initial leaf page, about to be split
NAME="leaf-page-split"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"

# no optimized
NAME="no-optimized-left-leaf-page-split"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
NAME="no-optimized-right-leaf-page-split"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
NAME="no-optimized-right-leaf-page-split-next"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
NAME="no-optimized-right-leaf-page-split-next-next"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"

# optimized
NAME="optimized-left-leaf-page-split"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
NAME="optimized-right-leaf-page-split"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
