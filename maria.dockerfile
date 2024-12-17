FROM debian:12.8

# Adiciona o usuário e grupo mysql para consistência
RUN groupadd -r mysql && useradd -r -g mysql mysql --home-dir /var/lib/mysql

# Instalar dependências e gosu
ENV GOSU_VERSION 1.17
ARG GPG_KEYS=177F4010FE56CA3336300305F1656F24C74CD1D8

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        gpg \
        gpgv \
        libjemalloc2 \
        pwgen \
        tzdata \
        xz-utils \
        zstd \
        dirmngr \
        gpg-agent \
        wget; \
    rm -rf /var/lib/apt/lists/*; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -q -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -q -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    GNUPGHOME="$(mktemp -d)"; \
    export GNUPGHOME; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEYS"; \
    gpg --batch --export "$GPG_KEYS" > /etc/apt/trusted.gpg.d/mariadb.gpg; \
    if command -v gpgconf >/dev/null; then \
        gpgconf --kill all; \
    fi; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    apt-mark auto '.*' > /dev/null; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true

# Diretório de inicialização
RUN mkdir /docker-entrypoint-initdb.d

# Configurar UTF-8 para o contêiner
ENV LANG C.UTF-8

# Anotações OCI para a imagem
LABEL org.opencontainers.image.authors="MariaDB Community" \
      org.opencontainers.image.title="MariaDB Database" \
      org.opencontainers.image.description="MariaDB Database for relational SQL" \
      org.opencontainers.image.documentation="https://hub.docker.com/_/mariadb/" \
      org.opencontainers.image.base.name="docker.io/library/debian:12.8" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.source="https://github.com/MariaDB/mariadb-docker" \
      org.opencontainers.image.vendor="MariaDB Community" \
      org.opencontainers.image.version="10.11" \
      org.opencontainers.image.url="https://github.com/MariaDB/mariadb-docker"

# Adicionar repositório MariaDB
RUN set -e; \
    echo "deb [trusted=yes] http://mariadb.mirror.globo.tech/repo/10.11/debian/ bookworm main" > /etc/apt/sources.list.d/mariadb.list; \
    { \
        echo 'Package: *'; \
        echo 'Pin: release o=MariaDB'; \
        echo 'Pin-Priority: 999'; \
    } > /etc/apt/preferences.d/mariadb

# Instalar MariaDB
RUN set -ex; \
    { \
        echo "mariadb-server" mysql-server/root_password password 'unused'; \
        echo "mariadb-server" mysql-server/root_password_again password 'unused'; \
    } | debconf-set-selections; \
    apt-get update; \
    apt-get install -y --no-install-recommends mariadb-server mariadb-backup socat; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /var/lib/mysql /run/mysqld; \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld; \
    chmod 1777 /run/mysqld; \
    find /etc/mysql/ -name '*.cnf' -print0 \
        | xargs -0 grep -lZE '^(bind-address|log|user\s)' \
        | xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/'; \
    # Alterar bind-address para permitir conexões externas
    echo "[mariadb]" > /etc/mysql/mariadb.conf.d/50-server.cnf; \
    echo "bind-address = 0.0.0.0" >> /etc/mysql/mariadb.conf.d/50-server.cnf; \
    # Configurar para desabilitar cache de nome e permitir conexões sem DNS
    printf "[mariadb]\nhost-cache-size=0\nskip-name-resolve\n" > /etc/mysql/mariadb.conf.d/05-skipcache.cnf; \
    if [ -L /etc/mysql/my.cnf ]; then \
        sed -i -e '/includedir/ {N;s/\(.*\)\n\(.*\)/\n\2\n\1/}' /etc/mysql/mariadb.cnf; \
    fi

# Inicializar e configurar o banco de dados
RUN /etc/init.d/mariadb start && mysql -u root -e  "CREATE USER 'wordpress'@'%' IDENTIFIED BY 'root_password'; \
CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; \
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%'; \
CREATE USER 'root'@'%' IDENTIFIED BY '1234'; \
ALTER USER 'root'@'localhost' IDENTIFIED BY '1234'; \
FLUSH PRIVILEGES;"

RUN sed -i "s/^bind-address.*$/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

# Expor a porta 3306 para o MariaDB
EXPOSE 3306

# Comando padrão
CMD ["mariadbd","--user=root"]

# export CB_LOCAL_HOST_ADDR=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)
#  docker run -it -p 3306:3306 --network wordpress-net --add-host=host.docker.internal:${CB_LOCAL_HOST_ADDR} --name test test