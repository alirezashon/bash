#!/bin/bash

mkdir testFolder
touch t.txt
nano test.tsx
for myPath in '*'; do
  echo $myPath
done

count=0
while [ $count -lt 1 ]; do
  echo "count  is : $count"
  count=$((count+1))
done

until [ $count -gt 1 ]; do
  echo "count  is : $count"
  count=$((count+1))
done 
 
echo "enter your score"
read Score

case $Score in
2) echo "number is 2" ;; 
3) echo "number is 3" ;;
4) echo "number is $Score" 
esac

name="Alireza"
echo hello world I am $name
if [ 15 -lt 7 ] || [ 3 -eq 3 ]; then
    echo "if condition is true"
elif [ $name = "Alireza" ]; then
    echo "you are alireza"    
else
    echo "you are in else"
fi