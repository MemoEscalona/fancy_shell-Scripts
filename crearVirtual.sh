#!/bin/sh
echo -n "Ingresa el dns del vhost : "
read dns
echo -n "Ingresa el correo electrónico: "
read mail
echo -n "Ingresa el usuario que debe tener permisos: "
read usuario
# creación de carpeta del proyecto
mkdir -p /var/www/${dns}
touch /var/www/${dns}/index.html
echo "<html><head><title>Hacker, go away.</title></head><body>Hi Hacker, go away!</body></html>" >> />

#creación de archivo de host
touch /etc/apache2/sites-available/${dns}.conf
echo "#### ${dns}
        <VirtualHost *:80>
            ServerAdmin ${mail}
            ServerName ${dns}
            DocumentRoot /var/www/${dns}
            <Directory /var/www/${dns}>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                Allow from all
                Require all granted
            </Directory>
        </VirtualHost>" >> /etc/apache2/sites-available/${dns}.conf
a2ensite ${dns}
service apache2 restart

#cambiarPermisos
chown -R ${usuario}:${usuario} /var/www/${dns}
chmod -R 775 /var/www/${dns}
