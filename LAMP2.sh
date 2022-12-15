#!/bin/bash
systemctl disable --now firewalld.service
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=enconfig/g' /etc/selinux/config
#Установка Git
 yum install -y epel-release
 yum install -y git
 mkdir project
 cd project
 git init
 cd /root/project/
 git clone git@github.com:skyfly535/Project.git
#Установка APACHE 
 yum install -y httpd
 \cp -u /root/project/Project/vhs.conf /etc/httpd/conf.d/
 \cp -u /root/project/Project/httpd.conf /etc/httpd/conf/
 \cp -u /root/project/Project/index.html /var/www/html/
 systemctl enable --now httpd
#Установка MySQL
 yum remove mariadb mariadb-servery
 rm -rf /etc/my.cnf.d
 rm -rf /var/lib/mysql
 rm -rf /etc/my.cnf
 rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-5.noarch.rpm
 sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
 yum --enablerepo=mysql80-community install mysql-community-server
 \cp -u /root/project/Project/my.cnf /etc/
 systemctl enable --now mysqld
 pas=`grep "A temporary password" /var/log/mysqld.log` 
 PASS=`echo $pas | awk '{print $NF}'`
 mysql -uroot -p$PASS --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'caching_sha2_password' BY 'Passw0rdSQL$';"
 mysql -uroot -pPassw0rdSQL$ -e "CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'Passw0rd$';"
 mysql -uroot -pPassw0rdSQL$ -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';"
 mysql -uroot -pPassw0rdSQL$ -e "FLUSH PRIVILEGES;"

 #\cp -u /root/project/Project/vhs.conf /etc/httpd/conf.d/
 #\cp -u /root/project/Project/httpd.conf /etc/httpd/conf/
 #-Xms1g
 #-Xmx1g/var/www/html/
#Установка ELK
 yum -y install java-openjdk-devel java-openjdk #можно без него
 #Монтируем шару хоста
 yum install cifs-utils #можно без него
 mkdir /mnt/win_share
 echo "ВВести пароль от хостовой машины"
 mount -t cifs -o username=User //192.168.152.1/Учёба /mnt/win_share
##ввести пароль
 cd /mnt/win_share/11-я\ домашка\ \(логирование\)/
 rpm -i elasticsearch_7.17.3_x86_64-224190-9bcb26.rpm
 rpm -i kibana_7.17.3_x86_64-224190-b13e53.rpm
 rpm -i logstash_7.17.3_x86_64-224190-3a605f.rpm
 rpm -i filebeat_7.17.3_x86_64-224190-4c3205.rpm
 \cp -u /root/project/Project/jvm.options /etc/elasticsearch/jvm.options.d/
 systemctl enable --now elasticsearch.service
 #curl http://127.0.0.1:9200
 curl -X PUT "http://127.0.0.1:9200/mytest_index" #можно без него
 \cp -u /root/project/Project/kibana.yml /etc/kibana/
 sudo systemctl enable --now kibana
 \cp -u /root/project/Project/logstash.yml /etc/logstash/
 \cp -u /root/project/Project/logstash-nginx-es.conf /etc/logstash/conf.d/
 sudo systemctl enable --now logstash.service
 systemctl restart logstash.service
 \cp -u /root/project/Project/filebeat.yml /etc/filebeat/
 systemctl enable --now filebeat
 #6-установка Node_exporter
 cd
 mkdir prometheus
 cd prometheus/
 wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0/node_exporter-1.4.0.linux-amd64.tar.gz
 tar -xvf node_exporter-1.4.0.linux-amd64.tar.gz
 rm node_exporter-1.4.0.linux-amd64.tar.gz #можно не удалаять
 useradd --no-create-home --shell /bin/false RKNode_exporter
 cd /root/prometheus/node_exporter-1.4.0.linux-amd64/
 rsync -P node_exporter /usr/local/bin #(из каталога где дистриб Node_exporter)#
 chown -v RKNode_exporter: /usr/local/bin/node_exporter
 \cp -u /root/project/Project/node_exporter.service /etc/systemd/system/
 systemctl enable --now node_exporter.service
      
exit 0