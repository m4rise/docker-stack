# Docker dev stack

## Features

#### Traefik Stack

- HAProxy exposing host machine docker socket to an internal network via tcp with configurable options
- Traefik		(traefik.localhost for dashboard)

#### Tools stack

- Portainer		(portainer.localhost)
- Maildev		(maildev.localhost)
- Adminer		(adminer.localhost)

#### LAMP extended stack

- PHP-Apache		(..., configure vhosts in lamp/conf/vhosts)
- Mysql
- PHPMyAdmin		(phpmyadmin.localhost)
- Node Yarn/NPM
- Redis

## Install specific step

- From project root, generate cert(s) with a tool like **[mkcert](https://github.com/FiloSottile/mkcert)** :

```bin/bash 
mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem "*.localhost" "*.loc" localhost phpmyadmin.localhost adminer.localhost node.localhost maildev.localhost portainer.localhost traefik.localhost 127.0.0.1 ::1 [...otherProjects]

mkcert -pkcs12 -p12-file certs/local-p12.p12 "*.localhost" "*.loc" localhost phpmyadmin.localhost adminer.localhost node.localhost maildev.localhost portainer.localhost traefik.localhost 127.0.0.1 ::1 [...otherProjects]
```

- Don't forget to update your **/etc/hosts** file for each vhost added

## More

The node container is mainly used to compile assets in Symfony projects with Webpack Encore.

Example command from /lamp folder, when all containers are built :

```bin/bash 
docker-compose run --rm -w /var/www/project nodejs yarn watch
```
