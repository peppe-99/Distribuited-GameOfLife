#!/bin/bash

# Delete oldest performance file
rm -rf general_test.txt

# Compile C file
mpicc distribuited-game-of-life.c -o distribuited-game-of-life

# Execute the program with differents num of process and matrix size
for size in 800 1600 3200 6400 12800
do
    for ((p=1; p<=8; p=p+1))
    do
        echo "Start program with $p process and ($size,$size) matrix"
        mpirun --allow-run-as-root -np $p distribuited-game-of-life $size $size 100 >> general_test.txt
    done
done

# Show performance
cat general_test.txt
