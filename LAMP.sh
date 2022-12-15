#!/bin/bash

      #1-Установка Git + firewalld + selinux
      systemctl disable --now firewalld.service
      setenforce 0
      sed -i 's/^SELINUX=.*/SELINUX=enconfig/g' /etc/selinux/config
      yum install -y epel-release
      yum install -y git
      mkdir project
      cd project
      git init
      #ssh-keygen -t ed25519 -C "roman@vm.com"
      #nano /root/.ssh/id_ed25519.pub
      
      #2-закачка файлов с GitHub 
      cd /root/project/
      git clone git@github.com:skyfly535/Project.git
      
      #3-Установка LAMP
      yum install -y httpd      
      \cp -u /root/project/Project/vh.conf /etc/httpd/conf.d/
      \cp -u /root/project/Project/httpd.conf /etc/httpd/conf/
      systemctl enable --now httpd
      yum remove mariadb mariadb-servery
      rm -rf /etc/my.cnf.d
      rm -rf /var/lib/mysql
      rm -rf /etc/my.cnf       
      rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-5.noarch.rpm
      sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
      yum --enablerepo=mysql80-community install mysql-community-server
      systemctl enable --now mysqld
      pas=`grep "A temporary password" /var/log/mysqld.log` 
      PASS=`echo $pas | awk '{print $NF}'`
      mysql -uroot -p$PASS --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'caching_sha2_password' BY 'Passw0rdSQL$';"
      yum install php php-mysql -y
      #5,5-настройка репликации      
      mysql -uroot -pPassw0rdSQL$ -e "CREATE USER repl@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'oTUSlave#2022';"
      mysql -uroot -pPassw0rdSQL$ -e "GRANT REPLICATION SLAVE ON *.* TO repl@'%';"
      mysql -uroot -pPassw0rdSQL$ -e "FLUSH PRIVILEGES;"
      # Закрываем и блокируем все таблицы
      #mysql -uroot -pPassw0rdSQL$ -e "FLUSH TABLES WITH READ LOCK;"      
      fbinlog=`mysql -uroot -pPassw0rdSQL$ -e 'SHOW MASTER STATUS;' | tail -1 | awk -F '\t' '{print $1}'`
      binpoos=`mysql -uroot -pPassw0rdSQL$ -e 'SHOW MASTER STATUS;' | tail -1 | awk -F '\t' '{print $2}'`
      mysql -uroot -h 192.168.152.155 -pPassw0rd$ -e "STOP SLAVE;"
      mysql -uroot -h 192.168.152.155 -pPassw0rd$ -e "CHANGE MASTER TO MASTER_HOST='192.168.152.153', MASTER_USER='repl', MASTER_PASSWORD='oTUSlave#2022', MASTER_LOG_FILE='$fbinlog', MASTER_LOG_POS=$binpoos, GET_MASTER_PUBLIC_KEY = 1;"
      #mysql -uroot -h 192.168.152.155 -pPassw0rd$ -e "CHANGE MASTER TO MASTER_HOST='192.168.152.153', MASTER_USER='repl', MASTER_PASSWORD='oTUSlave#2022', MASTER_LOG_FILE='binlog.000001', MASTER_LOG_POS=335538, GET_MASTER_PUBLIC_KEY = 1;"
      mysql -uroot -h 192.168.152.155 -pPassw0rd$ -e "START SLAVE;"
      # ОТкрываем и разблокируем все таблицы
      #mysql -uroot -pPassw0rdSQL$ -e "UNLOCK TABLES;"
      
      #5-установка NGINX и Joomla
      yum install -y nginx
      \cp -u /root/project/Project/default.conf /etc/nginx/conf.d/
      systemctl enable --now nginx
      wget https://github.com/joomla/joomla-cms/releases/download/3.7.2/Joomla_3.7.2-Stable-Full_Package.zip
      mkdir -p /var/www/html/joomla
      sudo unzip -q Joomla_3.7.2-Stable-Full_Package.zip -d /var/www/html/joomla
      chown -R $USER:$USER /var/www/html/joomla
      chown -R apache:apache /var/www/html/joomla
      chmod -R 755 /var/www/html/joomlay
      service httpd restart
      mysql -uroot -pPassw0rdSQL$ -e "CREATE DATABASE joomladb;"
      mysql -uroot -pPassw0rdSQL$ -e "CREATE USER 'joomla'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Passw0rd!';"
      mysql -uroot -pPassw0rdSQL$ -e "GRANT ALL PRIVILEGES ON joomladb.* TO 'joomla'@'localhost';"
      mysql -uroot -pPassw0rdSQL$ -e "FLUSH PRIVILEGES;"      

      #6-установка Prometheus
      cd
      mkdir prometheus
      cd prometheus/
      wget https://github.com/prometheus/prometheus/releases/download/v2.39.1/prometheus-2.39.1.linux-amd64.tar.gz
      tar -xvf prometheus-2.39.1.linux-amd64.tar.gz
      wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0/node_exporter-1.4.0.linux-amd64.tar.gz
      tar -xvf node_exporter-1.4.0.linux-amd64.tar.gz
      rm node_exporter-1.4.0.linux-amd64.tar.gz #можно не удалаять
      wget https://dl.grafana.com/oss/release/grafana-9.2.1-1.x86_64.rpm
      useradd --no-create-home --shell /usr/sbin/nologin RKPrometheus
      useradd --no-create-home --shell /bin/false RKNode_exporter
      mkdir -v {/etc,/var/lib}/prometheus
      chown -v RKPrometheus: {/etc,/var/lib}/prometheus
      cd /root/prometheus/node_exporter-1.4.0.linux-amd64/
      rsync -P node_exporter /usr/local/bin #(из каталога где дистриб Node_exporter)#
      chown -v RKNode_exporter: /usr/local/bin/node_exporter
      cd /root/prometheus/prometheus-2.39.1.linux-amd64/
      rsync -P prometheus /usr/local/bin #(из каталога где дистриб Node_exporter)#
      rsync -P promtool /usr/local/bin
      chown -v RKPrometheus: /usr/local/bin/prometheus
      chown -v RKPrometheus: /usr/local/bin/promtool
      \cp -u /root/project/Project/prometheus.service /etc/systemd/system/
      \cp -u /root/project/Project/node_exporter.service /etc/systemd/system/
      \cp -u /root/project/Project/prometheus.yml /etc/prometheus/
      cd /root/prometheus/prometheus-2.39.1.linux-amd64/
      cp -r consoles/ /etc/prometheus/
      cp -r console_libraries/ /etc/prometheus/
      cd /etc/prometheus/
      chown -v  RKPrometheus: prometheus.yml
      chown -v  RKPrometheus: consoles
      chown -v  RKPrometheus: console_libraries/
      chmod -R 777 /var/lib/prometheus
      systemctl enable --now node_exporter.service
      systemctl enable --now prometheus.service
      cd /root/prometheus/
      rm prometheus-2.39.1.linux-amd64.tar.gz
      yum install ./grafana-9.2.1-1.x86_64.rpm
      systemctl enable --now grafana-server.service
      ###################Filebeat###############################
      yum install cifs-utils
      mkdir /mnt/win_share
      mount -t cifs -o username=User //192.168.152.1/Учёба /mnt/win_share
      ##ввести пароль
      cd /mnt/win_share/11-я\ домашка\ \(логирование\)/
      rpm -i filebeat_7.17.3_x86_64-224190-4c3205.rpm
      \cp -u /root/project/Project/filebeat.yml /etc/filebeat/
      systemctl enable --now filebeat
      systemctl restart filebeat
      echo "Установка завершена!" 
exit 0