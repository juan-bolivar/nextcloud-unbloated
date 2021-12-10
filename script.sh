read -p  'Usuario admin:  ' username
read -p  'Clave admin: ' password
read -p 'Usuario db:  ' user_db
read -p 'Clave_db:  ' clave_db
read -p 'Change SSH port:   ' ssh_port
read -p 'Ingresar dominio:  ' domain


sudo apt update
sudo apt upgrade -y 
sudo apt install zip apache2 mariadb-server libapache2-mod-php7.4 -y
sudo apt install php7.4-gd php7.4-mysql php7.4-curl php7.4-mbstring php7.4-intl -y
sudo apt install php7.4-gmp php7.4-bcmath php-imagick php7.4-xml php7.4-zip -y


echo "CREATE USER '$user_db'@'localhost' IDENTIFIED BY '$clave_db';CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;GRANT ALL PRIVILEGES ON nextcloud.* TO '$user_db'@'localhost';FLUSH PRIVILEGES" | mysql


wget https://download.nextcloud.com/server/releases/nextcloud-20.0.0.zip
unzip nextcloud*
cp -r nextcloud/* /var/www/html/


echo "<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	#ServerName www.example.com

	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html
        ServerName www.$domain
	ServerAlias $domain
	# ServerAlias www.$domain
	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

	<Directory /var/www/html/>
  		   Require all granted
  		   AllowOverride All
  		   Options FollowSymLinks MultiViews

  		   <IfModule mod_dav.c>
    		   	     Dav off
  		   </IfModule>
	</Directory>

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with 'a2disconf'.
	#Include conf-available/serve-cgi-bin.conf
</VirtualHost>" > /etc/apache2/sites-available/nextcloud.conf

a2enmod ssl
a2ensite nextcloud.conf
a2dissite 000-default.conf
a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime

echo "ServerName $domain" >> /etc/apache2/apache2.conf

service apache2 reload
service apache2 restart

cd /var/www/html/

chown -R www-data:www-data /var/www/html/

sudo -u www-data php occ  maintenance:install --database mysql --database-name nextcloud --database-user $user_db --database-pass $clave_db --admin-user $username --admin-pass $password


sed -i 's/#Port 22/Port $ssh_port/g' /etc/ssh/sshd_config 
sed -i "s/0 =>\(.*\)/0 => \1 \n 1 => \'www.$domain\' , \n 2 => \'$domain\' , /" /var/www/html/config/config.php
sed -i "s/'overwrite.cli.url' => 'http:\/\/localhost'/'overwrite.cli.url' => 'https:\/\/www.$domain',\n\t'htaccess.RewriteBase' => '\/'/" /var/www/html/config/config.php

cd /var/www/html && sudo -u www-data php /var/www/html/occ maintenance:update:htaccess

cd /var/www/html && sudo -u www-data php -d memory_limit=1024M occ app:install richdocumentscode

#rm /var/www/html/index.html 

ufw allow 443
ufw allow 80
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --apache
service apache2 reload
systemctl restart sshd
