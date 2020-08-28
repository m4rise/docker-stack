# docker-stack

## Features

#### Traefik reverse proxy

#### Tools stack

- Portainer
- Maildev

#### LAMP extended stack

- PHP-Apache
- Mysql
- PHPMyAdmin
- Node (with Yarn/NPM)
- Redis

## Install specific step

- From project root, generate cert(s) with a tool like **[mkcert](https://github.com/FiloSottile/mkcert)** :

```bin/bash 
mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem "*.localhost" "*.loc" localhost 127.0.0.1 ::1
```

- Don't forget to update your **/etc/hosts** file

## More

The node container is mainly used to compile assets in Symfony projects with Webpack Encore.

Example command from /lamp folder, when all containers are built :

```bin/bash 
docker-compose run --rm -w /var/www/project nodejs yarn watch
```
