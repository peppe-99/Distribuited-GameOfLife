#!/bin/bash

# Delete oldest performance file
rm -rf results/weak_scalability.csv

# Compile the program
mpicc distribuited-game-of-life.c -o distribuited-game-of-life

# Add collumns names to CSV file
echo "TIME,PROCESSES,ROWS,COLS,GENERATIONS" >> results/weak_scalability.csv

# Exec the program with differents num of process and matrix size
size=1600
for ((p=1; p<=8; p=p+1))
do
    echo "Start program with $p process and ($((size*p)), 12800) matrix"
    mpirun --allow-run-as-root -np $p distribuited-game-of-life $((size*p)) 12800 100 >> results/weak_scalability.csv
done

# Show performance
cat results/weak_scalability.csv
