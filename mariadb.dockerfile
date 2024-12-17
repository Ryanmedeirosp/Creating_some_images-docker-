FROM debian:12.8

EXPOSE 3306

RUN apt update -y && apt install mariadb-server -y

## Configuração do MariaDB (criação da senha do root, criação do usuário WordPress)
#RUN mysql_secure_installation ???
RUN /etc/init.d/mariadb start && mysql -u root -e  "CREATE USER 'wordpress'@'%' IDENTIFIED BY 'root_password'; \
 CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; \
 GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%'; \
 ALTER USER 'root'@'localhost' IDENTIFIED BY '1234'; \
 FLUSH PRIVILEGES;"

## Configuração para habilitar o acesso remoto

# [Source: <https://mariadb.com/kb/en/configuring-mariadb-for-remote-client-access/>]
#RUN sed -i -e "/bind-address/ s/^/#/" -e "/\[mysqld\]/ askip-networking=0\nskip-bind-address" /etc/mysql/mariadb.conf.d/50-server.cnf
RUN sed -i "s/^bind-address.*$/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf


CMD ["mariadbd","--user=root"]

#  docker run -it -p 3306:3306 --network wordpress-net --name mariadb  mariadb