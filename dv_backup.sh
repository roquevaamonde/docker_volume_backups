#!/usr/bin/env bash

fecha=$(date +%d-%m-%Y)
path_log=/var/log/backups.log

function comprobar() {

  if [ $? != 0 ];
    then
      echo "$(date +%d-%m-%Y_%H:%M) $1 1" >> $2
      return 1
      exit 1
  else
      echo "$(date +%d-%m-%Y_%H:%M) $1 0" >> $2
      return 0
  fi
}

function check_dir() {

 ls $1 > /dev/null 2> /dev/null
 if [ $? == 0 ];
   then
     check_dir="skipping"
 else
   mkdir $1
     check_dir="created"
 fi
 comprobar "\"checkeo directorio $1\"" $path_log


}

function make_backup() {
  fecha_m=$(date +%Y%m%d)
  host=$1
  source_dir=$2
  user=$3
  backup_name=$4
  container=$5
  counter=0
  bcks_list=$(ls ./$backup_name | grep tar)
  rem=0
  rm -rf ./*/*.int
  for i in $(echo $bcks_list);
     do
       fecha_inicio=$(date +%s)
       fecha_fin=$(date --date=$(echo $i | awk -F"." '{ print $2 }') +%s)
       dif=$(( $fecha_inicio - $fecha_fin ))
       if [[ $dif -gt 604800 ]];
         then
           bcks_remd=($i "${bcks_remd[@]}")
           rm -f ./$backup_name/$i
        else
           bcks_perm=($i "${bcks_perm[@]}")
        fi
  done
  comprobar "\"Comprobacion backups antiguos, borrados: $(echo ${bcks_remd[@]}), permanecen: $(echo ${bcks_perm[@]})\"" $path_log
  bcks_remd=()
  bcks_perm=()
  while true;
    do
    check_dir ./$backup_name
    ssh $user@$host "docker stop $container"
    comprobar "\"Parando contenedor $backup_name con id $container\"" $path_log
    ssh $user@$host "tar -cvf /tmp/$(echo $source_dir | awk -F"/" '{ print $NF }').tar $source_dir;" &> /dev/null
    comprobar "\"Generacion tar en maquina origen $host para $backup_name como $(echo $source_dir | awk -F"/" '{ print $NF }').tar\"" $path_log
    ssh $user@$host "cksum /tmp/$(echo $source_dir | awk -F"/" '{ print $NF }').tar  > /tmp/o_cksum.$backup_name.$fecha_m.int"
    ssh $user@$host "docker start $container"
    comprobar "\"Arrancando contenedor $backup_name con id $container\"" $path_log
    scp -r $user@$host:/tmp/$(echo $source_dir | awk -F"/" '{ print $NF }').tar ./$backup_name/$backup_name.$fecha_m.tar
    comprobar "\"Copiando tar desde maquina origen $host a /usr/local/backups/$backup_name/$backup_name.$fecha_m.tar\"" $path_log
    scp -r $user@$host:/tmp/o_cksum.$backup_name.$fecha_m.int ./$backup_name/o_cksum.$backup_name.$fecha_m.int
    cksum $backup_name/$backup_name.$fecha_m.tar | awk '{ print $1 }' > ./$backup_name/d_cksum.$backup_name.$fecha_m.int
    if [ $(cat $backup_name/d_cksum.$backup_name.$fecha_m.int) != $(cat $backup_name/o_cksum.$backup_name.$fecha_m.int | awk '{ print $1 }') ];
      then
         counter=$counter+1
         if [ $counter -gt 4 ];
           then
             echo "$(date +%d-%m-%Y_%H:%M) \"Los cksum no han coincidido durante 5 intentos\" 1" >> $path_log
             exit
         fi
        continue
    else
        echo "$(date +%d-%m-%Y_%H:%M) \"Los cksum coinciden: [d:$(cat $backup_name/d_cksum.$backup_name.$fecha_m.int)] [o:$(cat $backup_name/o_cksum.$backup_name.$fecha_m.int | awk '{ print $1 }')]\" 0" >> $path_log
        break
    fi
 done
    ssh $user@$host "rm -f /tmp/$(echo $source_dir | awk -F"/" '{ print $NF }').tar"
    comprobar "\"Borrado tar origen\"" $path_log
    echo "$(date +%d-%m-%Y_%H:%M) \"Fin de backup con fecha $fecha_m guaradado en ./$backup_name como $backup_name.$fecha_m.tar\" 0" >> $path_log
}
echo "########################################################################################" >> $path_log
echo "$(date +%d-%m-%Y_%H:%M) \"Comienzo backup\" 0" >> $path_log
for i in $(cat backups.csv);
   do
   if [ $(echo $i | awk -F";" '{ print $1}') == "host" ];
    then
      continue
   else
      host=$(echo $i | awk -F";" '{ print $1 }')
      user=$(echo $i | awk -F";" '{ print $2 }')
      dir=$(echo $i | awk -F";" '{ print $3 }')
      name=$(echo $i | awk -F";" '{ print $4 }')
      container=$(echo $i | awk -F";" '{ print $5 }')
      make_backup $host $dir $user $name $container
      comprobar "\"Backup $name finaliza: \"" $path_log
   fi
done
echo "$(date +%d-%m-%Y_%H:%M) \"Fin backup\" 0" >> $path_log
echo "########################################################################################" >> $path_log
