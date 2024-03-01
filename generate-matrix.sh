#!/bin/bash

n=$1
m=$2
test_num=$3

echo $n >> test$test_num
for ((i=1; i<=$n; i++))
do
    ar=($(shuf -r -i 0-10 -n $m));
    echo "${ar[@]}" >> test$test_num;
done
