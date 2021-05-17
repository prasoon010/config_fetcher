#!/bin/bash

Red='\033[1;31m'
NC='\033[0m' # No Color
Green='\033[1;32m'

a_folder="/var/www/html/wiseconnect/api/config/autoload"
b_folder="/var/www/html/wiseconnect"
c_folder="/opt/tracesafe"
d_folder="/opt"
f_name="connection_settings.conf"
f_temp="connection_settings.conf_temp"
f_name1="config.json"
f_name2="redis.settings.php"
f_name3="mysql.settings.php"
f_name4="mqtt.settings.php"
f_name5="common_service_config.properties"
tmp_var="/var/log/app_connections/myvars.$$"

sudo mkdir -p /var/log/app_connections/


if [ -d ${c_folder} ];then
  if [ -s "${c_folder}/${f_name}" ];then
    echo -en "\n${Green}Base connection setting file found...!!!${NC}\n \n"
  else
    echo -en "\n${Red}Configuration file missing, copying from sample template...!!!${NC}\n"
    sudo cp ./${f_name} ${c_folder}/${f_name}
  if [ $? -ne 0 ];then echo -en "\n${Red}Copying conf template failed...!!!${NC}\n";exit;fi
  fi
else
  echo -en "\n${Red}Configuration directory missing, creating it now...!!!${NC}\n"
  sudo mkdir -p ${c_folder}
  sudo cp ./${f_name} ${c_folder}/${f_name}
  if [ $? -ne 0 ];then echo -en "\n${Red}Copying conf template failed...!!!${NC}\n";exit;fi
fi

sudo cp -a ${c_folder}/${f_name} ${c_folder}/${f_temp}

dpkg -s jq >/dev/null 2>&1
if [ $? -ne 0 ];then
 apt-get install jq
fi

conf_update()
{
 cat ${c_folder}/${f_temp}| grep "^${1}" > $tmp_var
 j=`cat $tmp_var| awk -F'=' '{print $1}'`
 sed -i "s|$j=.*|$j=${2}|g" ${c_folder}/${f_temp}
}

d_name=`cat ${b_folder}/api/config/settings.config.php |grep 'define("_DOMAIN_NAME"'|awk -F'"' '{print $4}'`
r_host=`cat ${a_folder}/${f_name2}| grep "'host' => '"|grep -v "//"|awk -F"'" '{print $4}'`
r_port=`cat ${a_folder}/${f_name2}| grep "'port' => '"|grep -v "//"|awk -F"'" '{print $4}'`
r_pwd=`cat ${a_folder}/${f_name2}| grep "'password' => '"|grep -v "//"|awk -F"'" '{print $4}'`
my_db=`jq .php_mysql.dbname ${b_folder}/${f_name1}| awk -F'"' '{print $2}'`
my_host=`jq .php_mysql.host ${b_folder}/${f_name1}| awk -F'"' '{print $2}'`
my_port=`cat ${a_folder}/${f_name3}|grep "'dsn' => '"| grep -v "//"| head -1| awk -F"port=" '{print $2}'|cut -d "'" -f1`
my_rw_usr=`jq .php_mysql.username ${b_folder}/${f_name1}| awk -F'"' '{print $2}'`
my_rw_pwd=`jq .php_mysql.password ${b_folder}/${f_name1}| awk -F'"' '{print $2}'`
my_ro_usr=`sed -n 29,35p ${a_folder}/${f_name3}| grep "'username' => '"| grep -v "//"| awk  -F"'" '{print $4}'`
my_ro_pwd=`sed -n 29,35p ${a_folder}/${f_name3}| grep "'password' => '"| grep -v "//"| awk  -F"'" '{print $4}'`
mq_host=`cat ${a_folder}/${f_name4}| grep "'host' => '"|grep -v "//"|awk -F"'" '{print $4}'`
mq_port=`cat ${a_folder}/${f_name4}| grep "'port' => '"|grep -v "//"|awk -F"'" '{print $4}'`
mq_id=`cat ${a_folder}/${f_name4}| grep "'clientId' => '"|grep -v "//"|awk -F"'" '{print $4}'`

gd_type=`cat ${d_folder}/${f_name5}| grep "^service.graph-database.choice"|awk -F"=" '{print $2}'`

if [ "${gd_type}" == 'neo4j' ];then

  gd_host=`cat ${d_folder}/${f_name5}|grep "^org.neo4j.driver.uri"|awk -F"=" '{print $2}'`
  gd_port=''
  gd_user=`cat ${d_folder}/${f_name5}|grep "^org.neo4j.driver.authentication.username"|awk -F"=" '{print $2}'`
  gd_pass=`cat ${d_folder}/${f_name5}|grep "^org.neo4j.driver.authentication.password"|awk -F"=" '{print $2}'`
  gd_dbname=`cat ${d_folder}/${f_name5}|grep "^org.neo4j.driver.custom.database"|awk -F"=" '{print $2}'`
  
elif [ "${gd_type}" == 'arango' ];then
  
  gd_host=`cat ${d_folder}/${f_name5}|grep "^arangodb.host"|awk -F"=" '{print $2}'`
  gd_port=`cat ${d_folder}/${f_name5}|grep "^arangodb.port"|awk -F"=" '{print $2}'`
  gd_user=`cat ${d_folder}/${f_name5}|grep "^arangodb.user"|awk -F"=" '{print $2}'`
  gd_pass=`cat ${d_folder}/${f_name5}|grep "^arangodb.password"|awk -F"=" '{print $2}'`
  gd_dbname=`cat ${d_folder}/${f_name5}|grep "^arangodb.custom.database"|awk -F"=" '{print $2}'`

fi


conf_update "server_domain_name" "${d_name}"
conf_update "redis_host" ${r_host}
conf_update "redis_port" ${r_port}
conf_update "redis_pwd" ${r_pwd}
conf_update "mysql_database" ${my_db}
conf_update "mysql_host" ${my_host}
conf_update "mysql_port" ${my_port}
conf_update "mysql_rw_user" ${my_rw_usr}
conf_update "mysql_rw_pwd" ${my_rw_pwd}
conf_update "mysql_ro_user" ${my_ro_usr}
conf_update "mysql_ro_pwd" ${my_ro_pwd}
conf_update "mqtt_broker_host" ${mq_host}
conf_update "mqtt_broker_port" ${mq_port}
conf_update "mqtt_client_id" ${mq_id}
conf_update "graph_db_type" ${gd_type}
conf_update "graph_db_host" ${gd_host}
conf_update "graph_db_port" ${gd_port}
conf_update "graph_db_user" ${gd_user}
conf_update "graph_db_pass" ${gd_pass}
conf_update "graph_db_name" ${gd_dbname}

while read -p "Save the fetched details to conf file?(y/n):" choice;do
 case $choice in 
   y|Y) sudo cp -a ${c_folder}/${f_temp} ${c_folder}/${f_name};a=$?;
        if [ "$a" -eq 0 ];then echo -en "\n${Green}Configuration file updated successfully${NC}\n";fi; break ;;
   n|N) echo -en "\n${Red}Configuration file updation aborted...!!!${NC}\n"; break ;;
   *) echo -en "\n${Red}Invalid input...!!!${NC}\n" ;;
 esac
done
