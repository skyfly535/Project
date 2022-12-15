#!/bin/bash
echo "Cоздание потабличног бекапа всех баз данных сервера (кроме служебные базы  с указанием позиции бинлога)"
# mkdir -p /root/project/Project/$destination/$fdate
for dbname in `echo show databases | mysql -uroot -pPassw0rdSQL$ | grep -v Database`; 
do
    case $dbname in
      information_schema)
      continue ;;
      mysql)
      continue ;;
      performance_schema)
      continue ;;
      sys)
      continue ;;
     *) for tablename in `echo show tables from $dbname | mysql -uroot -pPassw0rdSQL$ | grep -v Table`; 
           do
              mkdir -p /root/project/Project/$destination/$fdate/$dbname
              mysqldump -uroot -pPassw0rdSQL$ $dbname $tablename --events --routines --source-data=2 > /root/project/Project/$destination/$fdate/$dbname/$tablename.sql
              gzip /root/project/Project/$destination/$fdate/$dbname/$tablename.sql
              echo  "Бекап таблицы" $tablename "из базы данных" $dbname "создан"
            done
        esac
    #esac
done;
exit 0