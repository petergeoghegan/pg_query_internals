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
NAME="leaf-page-split"
echo "Generating $NAME.pdf..."
dot -T pdf "$NAME.dot" -o "$NAME.pdf"
