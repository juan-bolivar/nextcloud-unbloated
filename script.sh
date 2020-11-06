read -p  'Usuario admin:  ' username
read -p  'Clave admin:' password
read -p 'Usuario db:  ' user_db
read -p 'Clave_db:  ' clave_db
read -p 'Change SSH port:   ' ssh_port
useradd $username
usermod -aG sudo $username 

sudo apt update
sudo apt upgrade
sudo apt install zip apache2 mariadb-server libapache2-mod-php7.4 -y
sudo apt install php7.4-gd php7.4-mysql php7.4-curl php7.4-mbstring php7.4-intl -y
sudo apt install php7.4-gmp php7.4-bcmath php-imagick php7.4-xml php7.4-zip -y

sudo mysql -u $user_db -p$clave_db  

echo "CREATE USER '$user_db'@'localhost' IDENTIFIED BY '$clave_db';CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;GRANT ALL PRIVILEGES ON nextcloud.* TO '$user_db'@'localhost';FLUSH PRIVILEGES" | mysql


wget https://download.nextcloud.com/server/releases/nextcloud-20.0.0.zip
unzip nextcloud*
cp -r nextcloud/* /var/www/html/
echo 'Alias / "/var/www/html/"

<Directory /var/www/html/>
  Require all granted
  AllowOverride All
  Options FollowSymLinks MultiViews

   <IfModule mod_dav.c>
	Dav off
    </IfModule>
</Directory>' > /etc/apache2/sites-available/nextcloud.conf

a2enmod ssl

cd /var/www/html/

chown -R www-data:www-data /var/www/html/

sudo -u www-data php occ  maintenance:install --database \
	"mysql" --database-name "nextcloud"  --database-user "$user_db" --database-pass \
	"$clave_db" --admin-user "$username" --admin-pass "$password"



sed -i 's/#Port 22/Port $ssh_port/g' /etc/ssh/sshd_config 

sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --apache
service apache2 reload
