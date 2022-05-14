#!/bin/bash

# Delete oldest performance file
rm -rf strong_scalability.txt

# Compile C file
mpicc distribuited-game-of-life.c -o distribuited-game-of-life

# Execute the program with differents num of process and matrix size
size=12800
for ((p=1; p<=8; p=p+1))
do
    echo "Start program with $p process and ($size,$size) matrix"
    mpirun --allow-run-as-root -np $p distribuited-game-of-life $size $size 100 >> strong_scalability.txt
done


# Show performance
cat strong_scalability.txt
