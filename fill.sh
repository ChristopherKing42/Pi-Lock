#/bin/bash
emptykey=`find *.key -size 0`
head -c 16 /dev/random > $emptykey
