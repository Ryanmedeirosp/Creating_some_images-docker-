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
    apt upgrade -y && \
    apt install -y \
    php \
    php-mysql \
    php-curl \
    php-json \
    php-xml \
    php-mbstring \
    php-fpm

RUN sed -i -e "/^listen =/ s/^.*$/listen = 0.0.0.0:9000/" /etc/php/8.3/fpm/pool.d/www.conf
 
# COPY ./www.conf /etc/php/8.3/fpm/pool.d/www.conf

CMD ["bash", "-c", "php-fpm8.3 -F"]



