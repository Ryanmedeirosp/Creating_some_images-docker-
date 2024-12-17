# WordPress + MariaDB + Nginx + PHP-FPM em Docker

Este projeto configura um ambiente completo para rodar o WordPress utilizando MariaDB como banco de dados, Nginx como servidor web e PHP-FPM para processar os arquivos PHP. A configuração é feita utilizando Docker, com os contêineres interconectados via uma rede Docker personalizada (`wordpress-net`).

## Estrutura

1. **MariaDB**: Contêiner com o MariaDB configurado para aceitar conexões remotas, com um banco de dados e um usuário criado especificamente para o WordPress.
2. **Nginx**: Contêiner com o Nginx configurado para servir o WordPress e processar as requisições PHP.
3. **PHP-FPM**: Contêiner com o PHP-FPM configurado para processar os arquivos PHP do WordPress.

## Problemas com o NFS
1. Durante o desenvolvimento deste projeto, uma das funcionalidades que foi implementada inicialmente foi o uso do NFS (Network File System) para compartilhar o diretório do WordPress entre os contêineres. A ideia era que o Nginx e o PHP-FPM compartilhassem o mesmo volume de dados do WordPress por meio do NFS, garantindo consistência nos arquivos.

2. No entanto, após diversas tentativas de configuração e ajustes no Docker, o NFS não funcionou como esperado. Isso fez com que a aplicação não conseguisse acessar corretamente os arquivos compartilhados, afetando o funcionamento do WordPress. A configuração do NFS, especialmente a parte de compartilhamento de diretórios entre contêineres, foi um desafio técnico que não foi resolvido completamente no escopo deste projeto.

## Passos para Execução

1. **Criar a Rede Docker Personalizada**

   Antes de iniciar os contêineres, crie uma rede Docker personalizada para que os contêineres possam se comunicar entre si:

 
   docker network create wordpress-net

2. **Iniciar o Contêiner MariaDB**

   Crie e inicie o contêiner do MariaDB, configurando a porta `3306` para o acesso ao banco de dados:


   docker run -d -p 3306:3306 --name mariadb --network wordpress-net mariadb

   O contêiner MariaDB é configurado para:

   - Aceitar conexões externas (configurando `bind-address` para `0.0.0.0`).
   - Criar um banco de dados chamado `wordpress`.
   - Criar um usuário `wordpress` com permissões no banco de dados `wordpress`.

3. **Iniciar o Contêiner Nginx**

   Crie e inicie o contêiner Nginx, mapeando a porta `80` para o acesso HTTP:

   docker run -d -p 80:80 --name nginx --network wordpress-net nginx

   O Nginx está configurado para servir o WordPress e passar as requisições PHP para o PHP-FPM.

4. **Iniciar o Contêiner PHP-FPM**

   Crie e inicie o contêiner PHP-FPM, mapeando a porta `9000`:

   docker run -d -p 9000:9000 --name php-fpm --network wordpress-net php-fpm

   O PHP-FPM processa os arquivos PHP e os conecta ao banco de dados MariaDB.

5. **Acessar o WordPress**

   Após iniciar os contêineres, acesse o WordPress pelo navegador:
  
   http://localhost

   Complete a configuração do WordPress, fornecendo as informações do banco de dados, como o nome do banco (`wordpress`), usuário (`wordpress`), senha (`root_password`), e o host de banco de dados (`172.19.0.2`).

## Configuração do Banco de Dados

O MariaDB foi configurado com as seguintes credenciais para o WordPress:

- **Usuário**: wordpress
- **Senha**: root_password
- **Banco de Dados**: wordpress
- **Host**: 172.19.0.2 (IP do contêiner MariaDB na rede Docker)

## Configuração do Nginx

O Nginx está configurado para:

- Servir os arquivos do WordPress localizados no diretório `/var/www/html/wordpress`.
- Passar as requisições PHP para o PHP-FPM via FastCGI.

### Configuração do `nginx.conf`:


server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass php-fpm:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}


### Configuração do PHP-FPM no Dockerfile:

RUN sed -i -e "/^listen =/ s/^.*$/listen = 0.0.0.0:9000/" /etc/php/8.3/fpm/pool.d/www.conf

Além disso, o arquivo `wp-config.php` foi configurado com as credenciais de banco de dados do MariaDB.

## Configuração do WordPress

O WordPress foi baixado e descompactado no diretório `/var/www/html/wordpress` no contêiner PHP-FPM. O arquivo `wp-config.php` foi modificado para configurar o banco de dados.

### Configuração do `wp-config.php`:


define('DB_NAME', 'wordpress');
define('DB_USER', 'wordpress');
define('DB_PASSWORD', 'root_password');
define('DB_HOST', '172.19.0.2:3306');


## Considerações Finais

- Para produção, altere a senha do banco de dados e configure as chaves de segurança no arquivo `wp-config.php`.
- A comunicação entre os contêineres é feita através da rede Docker `wordpress-net`.
- O acesso ao banco de dados é feito via IP do contêiner MariaDB na rede interna Docker.



