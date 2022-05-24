#!/bin/bash

# Delete oldest performance file
rm -rf results/general_test.csv

# Compile the program
mpicc distribuited-game-of-life.c -o distribuited-game-of-life

# Add collumns names to CSV file
echo "TIME,PROCESSES,ROWS,COLS,GENERATIONS" >> results/general_test.csv

# Exex the program with differents num of process and matrix size
for size in 800 1600 3200 6400 12800
do
    for ((p=1; p<=8; p=p+1))
    do
        echo "Start program with $p process and ($size,$size) matrix"
        mpirun --allow-run-as-root -np $p distribuited-game-of-life $size $size 100 >> results/general_test.csv
    done
done

# Show performance
cat results/general_test.csv
