#!/bin/bash

mulist=`cat mu.dat | awk {printf "i4" $1}`
i=0
for mu in $mulist
do
  i=`echo $i+1|bc`
  cat Si_seebeck.dat | awk -v mu=$mu {if($1==mu){print $1,$2,$3,$7,$11} | awk -v Tcol=$i {if(NR==Tcol){print $1, $2, $3, $4, $5}} >> seebeck_vs_T.dat
done

