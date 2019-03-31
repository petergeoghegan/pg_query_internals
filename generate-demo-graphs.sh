#!/bin/bash
#
rm *.svg
NAME="lehman-yao-orthodox-btree"
echo "Generating $NAME.svg..."
dot -T svg "$NAME.dot" -o "$NAME.svg"
NAME="lehman-yao-orthodox-btree-suffix"
echo "Generating $NAME.svg..."
dot -T svg "$NAME.dot" -o "$NAME.svg"
NAME="lehman-yao-orthodox-btree-suffix-short"
echo "Generating $NAME.svg..."
dot -T svg "$NAME.dot" -o "$NAME.svg"
NAME="postgres-real-btree"
echo "Generating $NAME.svg..."
dot -T svg "$NAME.dot" -o "$NAME.svg"
