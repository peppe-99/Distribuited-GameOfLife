#!/bin/bash

# Delete oldest performance file
rm -rf weak_scalability.txt

# Compile C file
mpicc distribuited-game-of-life.c -o distribuited-game-of-life

# Execute the program with differents num of process and matrix size
size=1600
for ((p=1; p<=8; p=p+1))
do
    echo "Start program with $p process and ($((size*p)),$size) matrix"
    mpirun --allow-run-as-root -np $p distribuited-game-of-life $((size*p)) $size 100 >> weak_scalability.txt
done

# Show performance
cat weak_scalability.txt
