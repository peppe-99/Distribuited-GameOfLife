#!/bin/bash

# Delete oldest performance file
rm -rf performance.txt

# Compile C file
mpicc distribuited-game-of-life.c -o distribuited-game-of-life


# Execute the program with differents num of process and matrix size
for size in 1000 2500 5000 7500 10000
do
    for ((p=1; p<=8; p=p*2))
    do
        echo "Start program with $p process and ($size,$size) matrix"
        mpirun --allow-run-as-root -np $p distribuited-game-of-life $size $size 100 >> performance.txt
    done
done

# Show performance
cat performance.txt
