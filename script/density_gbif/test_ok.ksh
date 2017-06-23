for fich in list_*
do
awk '
  /^=/      {
              if (total_block_expected != total_block_real) 
              {
                #print fi " : " total_block_expected " " total_block_real; 
                wrong=1;
              }
              fi=$0;
              if (taxid != $2)
              {
                if (wrong == 0) print taxid
                wrong=0;
              }
              taxid = $2;
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
            }
  ' $fich
done

#grep '^X' list*
#grep 'exceptionReport' curl*
