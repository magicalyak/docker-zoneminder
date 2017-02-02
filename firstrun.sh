#!/bin/bash
  
  #Search for config files, if they don't exist, copy the default ones
  if [ ! -f /config/apache.conf ]; then
    echo "copying apache.conf"
    cp /root/apache.conf /config/apache.conf
  else
    echo "apache.conf already exists"
  fi

  if [ ! -f /config/zm.conf ]; then
    echo "copying zm.conf"
    cp /root/zm.conf /config/zm.conf
  else
    echo "zm.conf already exists"
  fi
  
  # Copy mysql database if it doesn't exit
  if [ ! -d /config/mysql/mysql ]; then
    echo "moving mysql to config folder"
    rm -r /config/mysql
    cp -p -R /var/lib/mysql /config/
  else
    echo "using existing mysql database"
  fi
  
  if [ ! -d /config/perl5 ]; then
    echo "moving perl data folder to config folder"
    mkdir /config/perl5
    cp -R -p /usr/share/perl5/ZoneMinder /config/perl5/
  else
    echo "using existing perl data directory"
  fi
  
  if [ ! -d /config/skins ]; then
    echo "moving skins folder to config folder"
    mkdir /config/skins
    cp -R -p /usr/share/zoneminder/www/skins /config/
  else
    echo "using existing skins directory"
  fi

  
  echo "creating symbolink links"
  rm -r /var/lib/mysql
  rm -r /etc/zm
  rm -r /usr/share/perl5/ZoneMinder
  rm -r /usr/share/zoneminder/www/skins
  ln -s /config/mysql /var/lib/mysql
  ln -s /config /etc/zm
  ln -s /config/perl5/ZoneMinder /usr/share/perl5/ZoneMinder
  ln -s /config/skins /usr/share/zoneminder/www/skins
  chown -R mysql:mysql /var/lib/mysql
  chmod -R go+rw /config
  
  # Create event folder
  if [ ! -d /var/cache/zoneminder/events ]; then
    echo "Create events folder"
    mkdir /var/cache/zoneminder/events
    chown -R root:www-data /var/cache/zoneminder/events
    chmod -R go+rw /var/cache/zoneminder/events
  else
    echo "using existing data directory"
  fi
  # Create images folder
  if [ ! -d /var/cache/zoneminder/images ]; then
    echo "Create events folder"
    mkdir /var/cache/zoneminder/images
    chown -R root:www-data /var/cache/zoneminder/images
    chmod -R go+rw /var/cache/zoneminder/images
  else
    echo "using existing data directory"
  fi
  # Create temp folder
  if [ ! -d /var/cache/zoneminder/temp ]; then
    echo "Create events folder"
    mkdir /var/cache/zoneminder/temp
    chown -R root:www-data /var/cache/zoneminder/temp
    chmod -R go+rw /var/cache/zoneminder/temp
  else
    echo "using existing data directory"
  fi

  #Get docker env timezone and set system timezone
  export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
  echo "setting the correct timezone : $TZ"
  echo $TZ > /etc/timezone
  ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
  dpkg-reconfigure tzdata
  echo "Date: `date`"
  sed -i "s|^date.timezone =.*$|date.timezone = ${TZ}|" /etc/php/7.0/apache2/php.ini
  #sed -e 's#\(\[mysqld\]\)#\1\ndefault-time-zone = '"'""$TZ""'"'#' -i /etc/mysql/my.cnf
  
  
  #fix memory issue
  echo "setting shared memory : $SHMEM of $MEM"
  umount /dev/shm
  mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=${SHMEM} tmpfs /dev/shm
  
  echo "starting services"
  service mysql start
  service apache2 start
  service zoneminder start

