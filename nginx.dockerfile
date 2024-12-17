FROM debian:12.8
RUN apt-get update -y && apt-get install -y \
    nginx \
    nfs-common \
    rpcbind && \
    apt-get clean

EXPOSE 80
#config nginx
COPY ./nginx /etc/nginx/sites-enabled/default 
WORKDIR /var/www/html


RUN sed -i -e '$ a php-fpm:/var/www/html /var/www/html nfs nolock,defaults 0 0' /etc/fstab
RUN mkdir /run/sendsigs.omit.d

#CMD ["bash", "-c", "rpcbind && nginx -g 'daemon off;'"]

CMD ["bash", "-c", "rpcbind && mount -a && nginx -g 'daemon off;'"]


#RUN apt-get install nfs-kernel-server -y
#RUN nano /etc/exports
#/var/www/html 10.254.4.0/24(rw,sync,no_subtree_check)
#mount 10.254.4.124:80:/var/www/html /var/www/html

## comando para run
#  docker run -it -p 80:80 --network wordpress-net --name nginx --privileged  nginx
