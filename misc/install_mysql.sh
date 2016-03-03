#!/bin/sh

. $(cd `dirname $0`; pwd | awk '{printf "/%s/%s/%s/etc/_common.conf", $2, $3, $4}' FS='/')

MY_ROOT_USER='root'
MY_ROOT_PASS='justmysql123!@#'
MY_SOCK=$MY_DIR/mysql.sock

service mysqld stop
killall -9 mysqld mysqld_safe

yum install -y mysql mysql-server

echo "
[mysqld]
datadir=$MY_DIR
socket=$MY_DIR/mysql.sock
user=mysql
symbolic-links=0
port=53306
character-set-server=utf8
character-set-filesystem=utf8
[mysqld_safe]
log-error=$LOG_DIR/mysqld.log
pid-file=$MY_DIR/mysqld.pid
[mysql]
no-auto-rehash
socket=$MY_DIR/mysql.sock
" >$ETC_DIR/my.cnf

[ -e /etc/my.cnf ] && mv -f /etc/my.cnf /etc/my.cnf.bk.`date +%Y%m%d-%H%M%S`
ln -s $ETC_DIR/my.cnf /etc/my.cnf
/usr/bin/mysql_install_db --verbose --skip-name-resolve --datadir=$MY_DIR --defaults-file=/etc/my.cnf
chkconfig mysqld on
service mysqld restart
#/usr/bin/mysql_secure_installation
/usr/bin/mysqladmin -S $MY_SOCK -u$MY_ROOT_USER password $MY_ROOT_PASS

echo "
use mysql;
delete from user where not (user='root' and host='localhost');
create database if not exists $MY_DB;
create user '$MY_USER'@'%' identified by '$MY_PASS';
grant ALL on $MY_DB.* to '$MY_USER'@'%';
update user set host='%' where user='root';
update user set host='%' where user='$MY_USER';
flush privileges;" |
mysql -S$MY_SOCK -h$MY_HOST -P$MY_PORT -u$MY_ROOT_USER -p$MY_ROOT_PASS
