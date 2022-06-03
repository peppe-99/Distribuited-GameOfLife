#!/bin/bash

# Delete oldest performance file
rm -rf results/strong_scalability.csv

# Compile the program
mpicc distribuited-game-of-life.c -o distribuited-game-of-life

# Add collumns names to CSV file
echo "TIME,PROCESSES,ROWS,COLS,GENERATIONS" >> results/strong_scalability.csv

# Exec the program with differents num of process and matrix size
size=12800
for ((p=1; p<=24; p=p+1))
do
    echo "Start program with $p process and ($size,$size) matrix"
    mpirun --allow-run-as-root -np $p --hostfile host distribuited-game-of-life $size $size 100 >> results/strong_scalability.csv
done

# Show performance
cat results/strong_scalability.csv
