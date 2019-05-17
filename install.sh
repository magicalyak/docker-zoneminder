#!/bin/bash

apt-get update && \
apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
apt-get dist-upgrade -y && \
apt-get install -y mariadb-server && \
cd /root && \
echo "UPDATE mysql.user SET Password=PASSWORD('zoneminder') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
" > mysql_secure_installation.sql && \


rm /etc/mysql/my.cnf && \
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/my.cnf && \

add-apt-repository -y ppa:iconnor/zoneminder && \
apt-get update --allow-unauthenticated && \
apt-get install --allow-unauthenticated -y zoneminder=1.30.0* php-gd && \
chmod 740 /etc/zm/zm.conf && \
chown root:www-data /etc/zm/zm.conf && \
adduser www-data video && \
a2enmod cgi && \
a2enconf zoneminder && \
a2enmod rewrite && \
chown -R www-data:www-data /usr/share/zoneminder/ && \
echo "
<Directory /usr/share>
        AllowOverride All
        Require all granted
</Directory>

<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>
" >> /etc/apache2/apache2.conf && \

sed -i "s|^;date.timezone =.*|date.timezone = ${TZ}|" /etc/php/7.0/apache2/php.ini && \
sed -i "s|^start() {$|start() {\n        sleep 15|" /etc/init.d/zoneminder && \

service mysql start && \
mysql -uroot < /usr/share/zoneminder/db/zm_create.sql && \
mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
mysqladmin -uroot reload
mysql -sfu root < "mysql_secure_installation.sql" && \
service mysql restart && \
service apache2 restart && \
service zoneminder restart && \
apt-get install --allow-unauthenticated -y wget usbutils libvlc-dev libvlccore-dev vlc usbutils && \
apt-get clean && \

chmod +x /etc/my_init.d/firstrun.sh && \
cp -p /etc/zm/zm.conf /root/zm.conf && \

update-rc.d -f apache2 remove && \
update-rc.d -f mysql remove && \
update-rc.d -f zoneminder remove

