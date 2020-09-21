#!/bin/bash

#################################################################################################################################
#               Autor: Guillermo Escalona Olivares                                                                              #
#               Descripción: Instala el stack de Apache, MySql, PHP (7.2) y PHPMyAdmin.                                         #
#                            Para la gestión del servidor se incluye la instalación de WebMin                                   #
#                            Para el sistema operativo 20.04.                                                                   #
#               Run: bash Install_amp.sh                                                                                        #
#               Notas: En caso de que exista algun error (Por Ejemplo: MySql) solo volver a correr el script.                   #
#                      Nada será reinstalador solo aquellos paquetes con errores.                                               #
#               Ultima Actualización: 19/09/2020 Guillermo Escalona                                                             #
#################################################################################################################################

#Definición de variables Para Base de datos
DB_USER="usuario_db"
DB_PWD="pwd_usuario_db"
DB_BD="nombre_db"
DB_ROOTPWD="contraseña_root"
PS_IPSERVER="IP_Externa" #0.0.0.0 desde cualquier lado
#Definición de variables Para Usuario a crear SO
SO_USER="usuario_so"
SO_PWD="contraseña_so"
#Definición de variables para PHPMYADMIN
PASS_PHPMYADMIN_APP="contraseña phpmyadmin"
#SSL DNS
DNS="dominio.com"
ADMIN_DNS="webmin.domino.com"
MAIL="soporte@dominio.com"


# Reset de Colores
Color_Off='\033[0m'       # Reset
# Definición de Colores
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

# Función que permite la actualización el repositorio del sistema operativo.
update() {
	echo "\n ${Cyan} Actualizado repositorios.. ${Color_Off}"
    apt-get update -qy  && apt-get upgrade -qy
    echo "\n ${Purple} Paquetes Basicos.. ${Color_Off}"
    apt-get -qy install htop && apt-get -qy install zsh
}

# Función que permite la instalación de la instalación de MySQL.
mysqldb(){
    if [ -f /etc/init.d/mysql* ]; then
        echo "\n ${Green} MySql ya se encuentra instalado ${Color_Off}"
    else 
        # MySQL
        echo "\n ${Green} Instalando MySQL.. ${Color_Off}"
        apt-get -qy install mysql-server 
        #Abrir puerto
        ufw allow 3306
        # Respaldar archivo de configuración
        cp /etc/mysql/mysql.conf.d/mysqld.cnf mysqld.cnf.resp
        # Reemplazar localhost por IP Server
        sed "s/127.0.0.1/${PS_IPSERVER}/g" mysqld.cnf.resp > /etc/mysql/mysql.conf.d/mysqld.cnf
        # Establecer modo de las contrasñeas
        echo "default-authentication-plugin=mysql_native_password" >> /etc/mysql/mysql.conf.d/mysqld.cnf
        #reiniciar servicio
        service mysql restart 
        # Hardering de la DB
        echo "\n ${Green} Hardering MySQL.. ${Color_Off}"
        # Eliminar usuarios anonimos
        mysql -e "DROP USER IF EXISTS ''@localhost"
        # Eliminar usuario anonimo con el valor del bash.
        mysql -e "DROP USER IF EXISTS ''@'$(hostname)';"
        # Eliminar base de datos de prueba
        mysql -e "DROP DATABASE IF EXISTS test;"
        # Eliminar usuarios anonimos
        mysql -e "DROP USER IF EXISTS '${DB_USER}'@localhost"
        # Eliminar usuario anonimo con el valor del bash.
        mysql -e "DROP USER IF EXISTS '${DB_USER}'@'%';"
        # Crear usuario BD con acceso remoto
        mysql -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED WITH 'mysql_native_password' BY '${DB_PWD}';"
        # Crear usuario BD con local
        mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '${DB_PWD}';"
        # Crear base de datos BD
        mysql -e "CREATE DATABASE ${DB_BD};"
        # Asignar privilegios sobre BD a usuario local
        mysql -e "GRANT ALL PRIVILEGES ON ${DB_BD}.* TO '${DB_USER}'@'localhost';"
        # Asignar privilegios sobre BD a usuario remoto
        mysql -e "GRANT ALL PRIVILEGES ON ${DB_BD}.* TO '${DB_USER}'@'%';"
        # Password for root
        # Establecer contraseña de usuario root
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '${DB_ROOTPWD}'; FLUSH PRIVILEGES;"
    fi
}

# Función que permite la instalación de Apache.
apache(){
    if [ -f /etc/init.d/apache2* ]; then
        echo "\n ${Red} Apache ya se encuentra instalado ${Color_Off}"
    else
        echo "\n ${Red} Instalando Apache ${Color_Off}"
        # instalamos apache
        apt -qy install apache2
        # abrimos puertos 80 y https
        ufw allow in "Apache Full"
        # habilitamos modulo de rewrite
        a2enmod rewrite
        # habilitamos modulo de cabeceras
        a2enmod headers
        # habilitamos proxy
        a2enmod proxy
        a2enmod proxy_http
        # reiniciamos apache
        service apache2 restart
    fi 
}

# Función que permite la instalación de PHP
php(){
    echo -e "\n ${Cyan} Installing modulos de php ${Color_Off}"
    # Agregamos repositorio de php
    add-apt-repository ppa:ondrej/php -y
    apt-get update -qy  && apt-get upgrade -qy
    # Instalamos PHP con sus modulos
    apt-get install -qy php7.2 php-pear php7.2-gd php7.2-zip php7.2-mbstring php7.2-mysql php7.2-xml php7.2-curl php7.2-curl php7.2-gd php7.2-intl php7.2-mbstring php7.2-xml php7.2-zip php7.2-apcu php7.2-memcached php-memcache php7.2-imagick php7.2-bcmath
    # Establecemos la version de php como la opcion predeterminada
    update-alternatives --set php /usr/bin/php7.2
    # reinciamos apache
    service apache2 restart
}

# Funcion que permite la instalacion de phpmyadmin
installPHPMyAdmin() {
	# PHPMyAdmin
	echo -e "\n ${Cyan} Installing PHPMyAdmin.. ${Color_Off}"
	# Establecer respuestas con  `debconf-set-selections` para no tener que interactuar con la terminal
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections # Establecer Tipo de Web Server
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections # Configure database para phpmyadmin con dbconfig-common
    echo "phpmyadmin phpmyadmin/mysql/app-pass password ${PASS_PHPMYADMIN_APP}" | debconf-set-selections  #Establecer MySQL application password para phpmyadmin
    echo "phpmyadmin phpmyadmin/app-password-confirm password ${PASS_PHPMYADMIN_APP}" | debconf-set-selections # Confirmación application password
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password ${DB_ROOTPWD}" | debconf-set-selections # MySQL Root Password
    echo "phpmyadmin phpmyadmin/internal/skip-preseed boolean true" | debconf-set-selections
	apt -qy install phpmyadmin
    service apache2 restart
}

# Funcion que permite la creacion de un usuario no root
usuario(){
    useradd -m -p $(openssl passwd -1 ${SO_PWD}) -s /bin/bash -G sudo ${SO_USER}
}

#funcion que permite instalar webmin
webmin(){
    echo "\n ${Purple} Webmin.. ${Color_Off}"
    echo "deb http://download.webmin.com/download/repository sarge contrib">>/etc/apt/sources.list
    wget -q -O- http://www.webmin.com/jcameron-key.asc | apt-key add
    apt-get update -qy
    apt-get -qy install webmin
    # Fix para webmin ssl
    cp /etc/webmin/miniserv.conf miniserv.conf.resp
    sed "s/ssl=1/ssl=0/g" miniserv.conf.resp > /etc/webmin/miniserv.conf
    systemctl restart webmin
}

#funcion que activa el SSL
ssl(){
    echo "\n ${Purple} SSL.. ${Color_Off}"
    # instalar certbot
    apt-get -qy install certbot python3-certbot-apache
    # crear sitio web inicial
    mkdir /var/www/${DNS}
    touch /var/www/${DNS}/index.html
    echo "<html><head><title>Hacker, go away.</title></head><body>Hi Hacker, go away!</body></html>" >> /var/www/${DNS}/index.html
    chown www-data:www-data /var/www/${DNS}
    chown www-data:www-data /var/www/${DNS}/index.html
    chmod -R 774 /var/www/${DNS}
    touch /etc/apache2/sites-available/${DNS}.conf
    touch /etc/apache2/sites-available/${ADMIN_DNS}.conf
    # Creación Virtual Host DNS
    echo "#### ${DNS}
        <VirtualHost *:80>
            ServerAdmin ${MAIL}
            ServerName ${DNS}
            DocumentRoot /var/www/${DNS}
            <Directory /var/www/${DNS}>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                Allow from all
                Require all granted
            </Directory>
        </VirtualHost>" >> /etc/apache2/sites-available/${DNS}.conf
    # Creación Virtual Host DNS
    echo "#### ${ADMIN_DNS}
        <VirtualHost *:80>
            ServerAdmin ${MAIL}
            ServerName ${ADMIN_DNS}
            ProxyPass / http://localhost:10000/
            ProxyPassReverse / http://localhost:10000/
        </VirtualHost>" >> /etc/apache2/sites-available/${ADMIN_DNS}.conf
    a2dissite /etc/apache2/sites-available/000-default.conf
    a2ensite ${DNS}
    a2ensite ${ADMIN_DNS}
    service apache2 restart
    # generación del certificado de ssl
    certbot -n --apache --agree-tos -d ${DNS} -m ${MAIL} --redirect
    certbot renew --dry-run
    certbot -n --apache --agree-tos -d ${ADMIN_DNS} -m ${MAIL} --redirect
    certbot renew --dry-run
}

# Ejecución secuencial
update
mysqldb
apache
php
installPHPMyAdmin
usuario
webmin
ssl