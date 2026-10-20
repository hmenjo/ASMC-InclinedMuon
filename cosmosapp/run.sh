#!/bin/bash -f

if [ -z "$1" ]; then
    echo "Usage: $0 <run_number>"
    exit 1
fi

run_number=`printf "%07d" $1`
export COSMOS_H5OUT=run${run_number}.h5 # output file name
export COSMOS_STDOUT=1 # stdout to file
time ./cosmosLinuxGfort < param > run${run_number}.out 2> run${run_number}.log # run the program    
