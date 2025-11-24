#!/bin/bash
# echo "enter"
# read  -n 2 -p "enter your password : " -s test
# echo $test

declare -A user
user[name]="Alireza"
user[age]=26

echo ${user[@]}

myFunction(){
 local myScore=4
((myScore+=5))
echo $myScore
echo $name
 myArray=("ali" "reza" "akbar")
myArray[3]="mohammad"
echo ${myArray[3]}

# echo $PATH
# echo $HOME
# echo $PWD
# echo $USER
# echo  $SHELL

# echo "Script name: $0"
# echo "Total args: $#"
# echo "First arg: $1"
# echo $$

}
# myFunction "my first Argument"

deploy(){
  local IP=$1
  local port=$2
  local user=$3
  echo $port $user"@"$IP 
  ssh -p $port $user"@"$IP
}
# deploy "8.8.8.8" "22" "root"



tested(){
select option in satart Stop Exit; do
  case $REPLY in
    1) echo "Starting..." ;;
    2) echo "Stopping..." ;;
    3) break ;;
    *) echo "Invalid option" ;;
  esac
done


case $Score in
2) echo "number is 2" ;; 
3) echo "number is 3" ;;
4) echo "number is $Score" 
esac

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


name="Alireza"
echo hello world I am $name
if [ 15 -lt 7 ] || [ 3 -eq 3 ]; then
    echo "if condition is true"
elif [ $name = "Alireza" ]; then
    echo "you are alireza"    
else
    echo "you are in else"
fi
}