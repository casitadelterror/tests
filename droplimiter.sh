#!/bin/bash

mostrar_usuarios () {
for u in `awk -F : '$3 > 900 { print $1 }' /etc/passwd | grep -v "nobody" |grep -vi polkitd |grep -vi system-`; do
echo "$u"
done
}
echo $$ > /tmp/pids
fun_drop () {
port_dropbear=`ps aux | grep dropbear | awk NR==1 | awk '{print $17;}'`
log=/var/log/auth.log
loginsukses='Password auth succeeded'
clear
pids=`ps ax |grep dropbear |grep  " $port_dropbear" |awk -F" " '{print $1}'`
for pid in $pids
do
    pidlogs=`grep $pid $log |grep "$loginsukses" |awk -F" " '{print $3}'`
    i=0
    for pidend in $pidlogs
    do
      let i=i+1
    done
    if [ $pidend ];then
       login=`grep $pid $log |grep "$pidend" |grep "$loginsukses"`
       PID=$pid
       user=`echo $login |awk -F" " '{print $10}' | sed -r "s/'/ /g"`
       waktu=`echo $login |awk -F" " '{print $2"-"$1,$3}'`
       while [ ${#waktu} -lt 13 ]; do
           waktu=$waktu" "
       done
       while [ ${#user} -lt 16 ]; do
           user=$user" "
       done
       while [ ${#PID} -lt 8 ]; do
           PID=$PID" "
       done
       echo "$user $PID $waktu"
    fi
done
}
mv -f /root/droplimiter.sh /bin/limit >/dev/null 2>&1
mv -f /home/droplimiter.sh /bin/limit >/dev/null 2>&1
if [ ! -z "$(mostrar_usuarios)" ]
then
	echo "usuarios no encontrado"
	exit 1
fi
while true
do
	clear
	echo -e "\E[42;1;37m               LIMITER DROPBEAR                \E[0m"
    echo -e "\E[42;1;37m Usuario                       Conexion/Limite \E[0m"
    while read usline
    do
		user="$(echo $usline | cut -d' ' -f1)"
		s2ssh="$(echo $usline | cut -d' ' -f2)"
		s3drop="$(fun_drop | grep "$user" | wc -l)"
		if [ -z "$user" ] ; then
		    echo "" > /dev/null
		else
		    fun_drop | grep "$user" | awk '{print $2}' |cut -d' ' -f2 > /tmp/userpid
		    sed -n '2 p' /tmp/userpid > /tmp/tmp2
		    rm /tmp/userpid
		    tput setaf 3 ; tput bold ; printf '  %-35s%s\n' $user $s3drop/$s2ssh; tput sgr0
		    if [ "$s3drop" -gt "$s2ssh" ]; then
		        echo -e "\E[41;1;37m Usuário desconectado por ultrapassar o limite! \E[0m"
		        while read line
		        do
		           tmp="$(echo $line | cut -d' ' -f1)"
		           kill $tmp
		        done < /tmp/tmp2
		        rm /tmp/tmp2
		    fi
		fi
     done < "$(mostrar_usuarios)"
     sleep 6
done
