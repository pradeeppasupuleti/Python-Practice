#!/bin/sh
echo "Enter host : "
read host
#echo "did number:"
#read did
scp -r chngbkp.sh $host:~

ssh -t $host sh chngbkp.sh
