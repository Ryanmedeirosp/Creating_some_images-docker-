FROM debian:12.8

EXPOSE 9000
# Atualiza o sistema e instala pacotes necessários
RUN apt update -y && \
    apt install -y \
    lsb-release \
    apt-transport-https \
    ca-certificates \
    wget && \
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list && \
    apt update -y && \
    apt install -y \
    php \
    php-mysql \
    php-curl \
    php-json \
    php-xml \
    php-mbstring \
    php-fpm

WORKDIR /var/www/html
RUN wget https://wordpress.org/latest.tar.gz && tar -xvzf latest.tar.gz
RUN chown -R nobody:nogroup /var/www/html && chmod -R 777 /var/www/html
#chown -R www-data: /var/www/html/ && chmod -R 755 /var/www/html/
    
#Config wordpress
COPY ./wp-config.php /var/www/html/wordpress/wp-config.php

RUN sed -i -e "/^listen =/ s/^.*$/listen = 0.0.0.0:9000/" /etc/php/8.3/fpm/pool.d/www.conf

RUN apt-get install nfs-kernel-server -y
RUN sed -i '$ a /var/www/html 172.19.0.0/16(rw,sync,no_subtree_check)' /etc/exports


#RUN exportfs -ra

#RUN apt-get install nfs-kernel-server -y
#RUN sed -i '$ a /var/www/html 172.19.0.0/24(rw,sync,no_subtree_check)' /etc/exports
# RUN exports -ra
# RUN mount -t nfs 10.254.4.101:/var/www/html /var/www/html

CMD ["bash", "-c", "php-fpm8.3 -F"]


## comando para run
#  docker run -it -p 9000:9000 --network wordpress-net --privileged --name php-fpm php-fpm 
