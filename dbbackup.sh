#!/bin/bash
mkdir -p /home/dbbackups
path="/home/dbbackups"
today=`date +%F`
dow=`date +%a`
# List all databases in server

mysql -e "show databases" | egrep -vw "(Database|information_schema|performance_schema)" > $path/dblist.txt

rm -fv $path/dbfailed.txt
rm -fv $path/dbfailed-tmp.txt
rm -fv $path/dbfailed-mail.txt
mkdir -p $path/$dow
/usr/bin/mysqldump --events mysql > $path/$dow/mysql.sql

if [ $? -ne 0 ] ;
then
mysqlcheck -r mysql ;
/usr/bin/mysqldump --events mysql > $path/$dow/mysql.sql
if [ $? -ne 0 ] ;
then
echo "mysql" > $path/dbfailed.txt;
fi
fi

for i in `cat $path/dblist.txt` ;
do
sleep 2;
echo "Creating dbbackup of $i" ;
/usr/bin/mysqldump $i > $path/$dow/$i.sql ;
if [ $? -ne 0 ] ;
then
echo $i >> $path/dbfailed-tmp.txt;
fi;
done

if [ -f $path/dbfailed-tmp.txt ]
then

for i in `cat $path/dbfailed-tmp.txt`
do
mysqlcheck -r $i
/usr/bin/mysqldump $i > $path/$dow/$i.sql ;
if [ $? -ne 0 ] ;
then
echo $i >> $path/dbfailed.txt;
fi;
done
fi

find /home/dbbackups/* -type f -mtime +30 -exec rm -f {} \;
