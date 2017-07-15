#!/bin/bash
echo -e "Content-type: text/html\n"
#ls motion/fotos/ | sort -r
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
printf "["
for f in `ls -vr motion/fotos/` ; do
  printf  " \"%s\"," "$f"
done
printf " \"\"]"
IFS=$SAVEIFS
