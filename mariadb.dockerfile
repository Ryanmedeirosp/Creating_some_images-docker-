FROM debian:12.8

EXPOSE 3306

RUN apt update -y && apt install mariadb-server -y

## Configuração do MariaDB (criação da senha do root, criação do usuário WordPress)
#RUN mysql_secure_installation ???
RUN /etc/init.d/mariadb start && mysql -u root -e  "CREATE USER 'username'@'%' IDENTIFIED BY 'password'; \
 CREATE DATABASE databsename CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; \
 GRANT ALL PRIVILEGES ON databsename.* TO 'username'@'%'; \
 ALTER USER 'root'@'localhost' IDENTIFIED BY 'password'; \
 FLUSH PRIVILEGES;"

## Configuração para habilitar o acesso remoto
# RUN sed -i -e "/bind-address/ s/^/#/" -e "/bind-address/ asql-mode=\"NO_ENGINE_SUBSTITUTION\"" /etc/mysql/mariadb.conf.d/50-server.cnf
# [Source: <https://mariadb.com/kb/en/configuring-mariadb-for-remote-client-access/>]
RUN sed -i -e "/bind-address/ s/^/#/" -e "/[mysqld]/ askip-networking=0\nskip-bind-address" /etc/mysql/mariadb.conf.d/50-server.cnf
# RUN sed -i -e "/port/ s/^# //" -e "/^socket/ s/^/#/" /etc/mysql/mariadb.cnf

CMD ["mariadbd","--user=root"]
