FROM debian:12.8
RUN apt-get update -y && apt-get install nginx wget -y

EXPOSE 80
#config nginx
COPY ./nginx /etc/nginx/sites-enabled/default 
WORKDIR /var/www/html
RUN wget https://wordpress.org/latest.tar.gz && tar -xvzf latest.tar.gz
RUN chown -R www-data: /var/www/html/ && chmod -R 755 /var/www/html/

COPY ./wp-config.php /var/www/html/wordpress/wp-config-sample.php 

RUN mv /var/www/html/wordpress/wp-config-sample.php  /var/www/html/wordpress/wp-config.php 

# CMD [ "nginx", "-g", "daemon off;"]

CMD ["bash", "-c", "nginx -g 'daemon off;'"]

#config do wordpress criação do wp-config.php que é automatico quando conecta com o banco de dados
#RUN apt-get install nfs-kernel-server -y

