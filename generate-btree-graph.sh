#!/bin/bash
#
# Generate an svg image of the B-Tree index specified within
# graphviz-query.sql.
#
# Assumes that psql and graphviz dot are in $PATH

echo "generating dot file..."
time psql -f graphviz-query.sql --no-psqlrc --no-align -t > /tmp/query-btree.dot
echo "generating svg file..."
time dot -T svg /tmp/query-btree.dot -o /tmp/query-btree.svg
