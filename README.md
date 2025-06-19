# Stack Docker de Développement Sécurisée

Une stack complète pour le développement local avec HTTPS, monitoring et outils intégrés.

## 🚀 Démarrage rapide

```bash
# Initialisation (première utilisation)
./manage-stack.sh init

# Démarrage de la stack
./manage-stack.sh start

# Arrêt de la stack
./manage-stack.sh stop
```

## 📋 Services disponibles

### Proxy & Administration
- **Traefik Dashboard**: https://traefik.localhost (admin/admin)
- **Portainer**: https://portainer.localhost

### Bases de données
- **PostgreSQL**: `postgres:5432` (postgres/root)
- **MariaDB**: `mariadb:3306` (root/root)
- **MongoDB**: `mongo:27017` (root/root)
- **Redis**: `redis:6379`
- **Elasticsearch**: `elasticsearch:9200`

### Outils de développement
- **PGAdmin**: https://pgadmin.localhost (contact@damien-duval.fr/admin)
- **RabbitMQ Management**: https://rabbitmq.localhost (admin/admin)
- **Inbucket (Email)**: https://inbucket.localhost
- **Code Server**: https://code.localhost
- **Swagger UI**: https://swagger.localhost
- **MockServer**: https://mock.localhost

### Monitoring
- **Grafana**: https://grafana.localhost (admin/admin)
- **Prometheus**: https://prometheus.localhost

### Utilitaires
- **HTTPBin**: https://httpbin.localhost

## 🔧 Commandes de gestion

```bash
./manage-stack.sh init      # Initialise la stack
./manage-stack.sh start     # Démarre tous les services
./manage-stack.sh stop      # Arrête tous les services
./manage-stack.sh restart   # Redémarre tous les services
./manage-stack.sh status    # Affiche le statut des services
./manage-stack.sh services  # Liste les services disponibles
./manage-stack.sh update    # Met à jour les images Docker
./manage-stack.sh cleanup   # Nettoie les ressources inutilisées
./manage-stack.sh logs      # Affiche les logs en temps réel
```

## 🐳 Intégration d'un nouveau projet

1. Copiez le fichier `project-template.yml` dans votre projet
2. Renommez-le en `docker-compose.yml`
3. Adaptez la configuration selon vos besoins
4. Démarrez votre projet avec `docker-compose up -d`

Votre application sera automatiquement accessible via HTTPS.

## 🔐 Configuration des certificats SSL

Pour un environnement HTTPS/TLS fonctionnel, vous devez générer des certificats SSL locaux avec **[mkcert](https://github.com/FiloSottile/mkcert)**.

### Installation de mkcert

```bash
# Sur Ubuntu/Debian
sudo apt install libnss3-tools
wget -O mkcert https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v*-linux-amd64
chmod +x mkcert
sudo mv mkcert /usr/local/bin/

# Sur macOS
brew install mkcert

# Installer l'autorité de certification locale
mkcert -install
```

### Génération des certificats

Depuis la racine du projet, générez les certificats pour tous les services :

```bash
# Certificat principal pour tous les services
mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem \
  "*.localhost" "*.loc" localhost \
  traefik.localhost portainer.localhost \
  pgadmin.localhost rabbitmq.localhost \
  inbucket.localhost code.localhost \
  swagger.localhost mock.localhost \
  grafana.localhost prometheus.localhost \
  httpbin.localhost \
  127.0.0.1 ::1

# Certificat PKCS12 (optionnel, pour certaines applications)
mkcert -pkcs12 -p12-file certs/local-p12.p12 \
  "*.localhost" "*.loc" localhost \
  traefik.localhost portainer.localhost \
  pgadmin.localhost rabbitmq.localhost \
  inbucket.localhost code.localhost \
  swagger.localhost mock.localhost \
  grafana.localhost prometheus.localhost \
  httpbin.localhost \
  127.0.0.1 ::1
```

### Configuration du fichier hosts

Ajoutez les domaines à votre fichier `/etc/hosts` :

```bash
sudo tee -a /etc/hosts << EOF
# Docker Development Stack
127.0.0.1 traefik.localhost
127.0.0.1 portainer.localhost
127.0.0.1 pgadmin.localhost
127.0.0.1 rabbitmq.localhost
127.0.0.1 inbucket.localhost
127.0.0.1 code.localhost
127.0.0.1 swagger.localhost
127.0.0.1 mock.localhost
127.0.0.1 grafana.localhost
127.0.0.1 prometheus.localhost
127.0.0.1 httpbin.localhost
# Ajoutez ici vos projets personnels
# 127.0.0.1 mon-projet.localhost
EOF
```

> **Note** : Pour chaque nouveau projet que vous ajoutez, pensez à :
> 1. Ajouter le domaine à `/etc/hosts`
> 2. Régénérer les certificats avec le nouveau domaine si nécessaire

## 🐛 Dépannage des certificats SSL

### Problèmes courants avec les certificats

#### Certificats non reconnus par le navigateur

1. **Vérifiez que mkcert est installé et configuré** :
   ```bash
   mkcert -install
   ```

2. **Régénérez les certificats** :
   ```bash
   rm certs/local-*.pem
   ./manage-stack.sh mkcert
   ```

3. **Redémarrez Traefik** :
   ```bash
   docker-compose -f traefik/docker-compose.yaml restart
   ```

#### Erreur "NET::ERR_CERT_AUTHORITY_INVALID"

- Assurez-vous que l'autorité de certification de mkcert est installée :
  ```bash
  mkcert -install
  ```
- Redémarrez votre navigateur après l'installation

#### Domaine non accessible

1. **Vérifiez le fichier hosts** :
   ```bash
   cat /etc/hosts | grep localhost
   ```

2. **Ajoutez le domaine manquant** :
   ```bash
   echo "127.0.0.1 mon-nouveau-projet.localhost" | sudo tee -a /etc/hosts
   ```

3. **Régénérez les certificats avec le nouveau domaine** :
   ```bash
   ./manage-stack.sh mkcert
   ```

#### Renouvellement des certificats

Les certificats mkcert n'expirent pas, mais si vous devez les renouveler :

```bash
# Supprimez les anciens certificats
rm certs/local-*.pem

# Régénérez avec tous vos domaines
./manage-stack.sh mkcert
```
