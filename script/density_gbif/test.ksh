taxdone=$(cat list_* | awk '/^=/ {print $2}' | sort -u | wc -l)
totdone=$(grep ^= list_* | wc -l)
tottodo=$(wc -l gbif.lst)

number=3

echo
echo "Current status : $totdone calls done - $taxdone/$tottodo"
echo

#Check processes running
proc=$(ps aux | grep "getmaps\\.rb" | wc -l)

if [ $proc -ne $number ]
then
  echo "WARNING ! SOME PROCESSES STOPED !"
  echo
  ps aux | grep "getmaps\\.rb"
fi


# Check files are being updated
curlupdated=$(find . -name 'curl*' -mmin -300 | wc -l)
if [ $curlupdated -ne $number ]
then
  echo "WARNING ! SOME CURL FILES HAVE NOT BEEN UPDATED FOR 5 hours"
  echo
  find . -name 'curl*' -mmin -300
fi

listupdated=$(find . -name 'list*' -mmin -500 | wc -l)
if [ $listupdated -ne $number ]
then
  echo "WARNING ! SOME LIST FILES HAVE NOT BEEN UPDATED FOR 8 hours"
  echo
  find . -name 'curl*' -mmin -500
fi


for fich in list_*
do
awk '/^=/   {
              if (total_block_expected != total_block_real) print fi " : " total_block_expected " " total_block_real; 
              fi=$0;
              total_block_expected = -1;
              total_block_real=0;
            } 
  /^@/      {
              total_file_expected+=$3;
              total_block_expected=$3;
              total_block_real=0;
            } 
  /^#/      {
              total_block_real+=1 ; 
              total_file_real+=1;
            } 
  END       {
              print "Total : " total_file_expected " - " total_file_real;
            }
  ' $fich
done

#grep '^X' list*
#grep 'exceptionReport' curl*
