#!/bin/bash

# Stack Docker de développement sécurisée
# Script de gestion centralisé

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="dev-stack"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis
check_requirements() {
    log "Vérification des prérequis..."

    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose n'est pas installé"
        exit 1
    fi

    log "Prérequis OK"
}

# Création des réseaux Docker
create_networks() {
    log "Création des réseaux Docker..."

    # Réseau principal Traefik
    if ! docker network ls | grep -q "traefik"; then
        docker network create \
            --driver bridge \
            --subnet=172.18.0.0/24 \
            --ip-range=172.18.0.0/24 \
            traefik
        log "Réseau 'traefik' créé"
    else
        log "Réseau 'traefik' existe déjà"
    fi

    # Réseau pour le proxy Docker socket
    if ! docker network ls | grep -q "docker-socket-proxy"; then
        docker network create \
            --driver bridge \
            --subnet=172.19.0.0/24 \
            --ip-range=172.19.0.0/24 \
            docker-socket-proxy
        log "Réseau 'docker-socket-proxy' créé"
    else
        log "Réseau 'docker-socket-proxy' existe déjà"
    fi
}

# Génération des certificats SSL avec mkcert (recommandé) ou OpenSSL (fallback)
generate_certs() {
    log "Génération des certificats SSL..."

    CERTS_DIR="$SCRIPT_DIR/certs"
    mkdir -p "$CERTS_DIR"

    if [[ ! -f "$CERTS_DIR/local-cert.pem" || ! -f "$CERTS_DIR/local-key.pem" ]]; then
        # Vérifier si mkcert est disponible
        if command -v mkcert &> /dev/null; then
            log "Utilisation de mkcert pour générer les certificats..."
            mkcert -cert-file "$CERTS_DIR/local-cert.pem" -key-file "$CERTS_DIR/local-key.pem" \
                "*.localhost" "*.loc" localhost \
                traefik.localhost portainer.localhost \
                pgadmin.localhost rabbitmq.localhost \
                inbucket.localhost code.localhost \
                swagger.localhost mock.localhost \
                grafana.localhost prometheus.localhost \
                httpbin.localhost \
                127.0.0.1 ::1
            log "Certificats SSL générés avec mkcert"
        else
            warn "mkcert non trouvé, utilisation d'OpenSSL (certificats auto-signés basiques)"
            openssl req -x509 -newkey rsa:4096 -keyout "$CERTS_DIR/local-key.pem" \
                -out "$CERTS_DIR/local-cert.pem" -days 365 -nodes \
                -subj "/C=FR/ST=France/L=Local/O=Development/OU=IT Department/CN=*.localhost"
            warn "Certificats générés avec OpenSSL. Pour une meilleure expérience, installez mkcert."
        fi
    else
        log "Certificats SSL existent déjà"
    fi
}

# Initialisation des fichiers de configuration
init_configs() {
    log "Initialisation des configurations..."

    # Copie des fichiers d'exemple
    for env_file in $(find "$SCRIPT_DIR" -name "sample.env"); do
        env_target="${env_file%sample.env}.env"
        if [[ ! -f "$env_target" ]]; then
            cp "$env_file" "$env_target"
            log "Fichier $env_target créé"
        fi
    done

    # Création des dossiers de données
    mkdir -p "$SCRIPT_DIR"/{lamp,tools}/data
    mkdir -p "$SCRIPT_DIR"/lamp/logs/{apache2,mysql,postgres}

    log "Configuration initialisée"
}

# Démarrage de la stack
start_stack() {
    log "Démarrage de la stack de développement..."

    # Traefik en premier
    log "Démarrage de Traefik..."
    docker-compose -f "$SCRIPT_DIR/traefik/docker-compose.yaml" up -d

    # Attendre que Traefik soit prêt
    sleep 5

    # Services LAMP
    log "Démarrage des services LAMP..."
    docker-compose -f "$SCRIPT_DIR/lamp/docker-compose.yaml" up -d

    # Outils de développement
    log "Démarrage des outils..."
    docker-compose -f "$SCRIPT_DIR/tools/docker-compose.yaml" up -d

    log "Stack démarrée avec succès!"
    show_services
}

# Arrêt de la stack
stop_stack() {
    log "Arrêt de la stack..."

    docker-compose -f "$SCRIPT_DIR/tools/docker-compose.yaml" down
    docker-compose -f "$SCRIPT_DIR/lamp/docker-compose.yaml" down
    docker-compose -f "$SCRIPT_DIR/traefik/docker-compose.yaml" down

    log "Stack arrêtée"
}

# Affichage des services disponibles
show_services() {
    log "Services disponibles:"
    echo ""
    echo -e "${BLUE}Proxy & Administration:${NC}"
    echo "  - Traefik Dashboard: https://traefik.localhost"
    echo "  - Portainer: https://portainer.localhost"
    echo ""
    echo -e "${BLUE}Bases de données:${NC}"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - MariaDB: localhost:3306"
    echo "  - MongoDB: localhost:27017"
    echo "  - Redis: localhost:6379"
    echo ""
    echo -e "${BLUE}Outils de développement:${NC}"
    echo "  - PGAdmin: https://pgadmin.localhost"
    echo "  - RabbitMQ Management: https://rabbitmq.localhost"
    echo "  - Inbucket (Email): https://inbucket.localhost"
    echo "  - Code Server: https://code.localhost"
    echo ""
    echo -e "${BLUE}Monitoring:${NC}"
    echo "  - Grafana: https://grafana.localhost"
    echo "  - Prometheus: https://prometheus.localhost"
    echo ""
    echo -e "${BLUE}Utilitaires:${NC}"
    echo "  - HTTPBin: https://httpbin.localhost"
}

# Mise à jour des images
update_images() {
    log "Mise à jour des images Docker..."

    docker-compose -f "$SCRIPT_DIR/traefik/docker-compose.yaml" pull
    docker-compose -f "$SCRIPT_DIR/lamp/docker-compose.yaml" pull
    docker-compose -f "$SCRIPT_DIR/tools/docker-compose.yaml" pull

    log "Images mises à jour"
}

# Nettoyage
cleanup() {
    log "Nettoyage des ressources Docker..."

    docker system prune -f
    docker volume prune -f
    docker network prune -f

    log "Nettoyage terminé"
}

# Fonction d'aide
show_help() {
    echo "Script de gestion de la stack Docker de développement"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init     - Initialise la stack (réseaux, certificats, configs)"
    echo "  mkcert   - Configure mkcert et génère les certificats SSL"
    echo "  start    - Démarre tous les services"
    echo "  stop     - Arrête tous les services"
    echo "  restart  - Redémarre tous les services"
    echo "  status   - Affiche le statut des services"
    echo "  services - Affiche la liste des services disponibles"
    echo "  update   - Met à jour toutes les images Docker"
    echo "  cleanup  - Nettoie les ressources Docker inutilisées"
    echo "  logs     - Affiche les logs de tous les services"
    echo "  help     - Affiche cette aide"
}

# Aide pour l'installation et configuration de mkcert
setup_mkcert() {
    log "Configuration de mkcert pour les certificats SSL..."

    if ! command -v mkcert &> /dev/null; then
        echo ""
        warn "mkcert n'est pas installé. Installation recommandée pour des certificats SSL valides."
        echo ""
        echo -e "${BLUE}Instructions d'installation :${NC}"
        echo ""
        echo "Ubuntu/Debian :"
        echo "  sudo apt install libnss3-tools"
        echo "  wget -O mkcert https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v*-linux-amd64"
        echo "  chmod +x mkcert && sudo mv mkcert /usr/local/bin/"
        echo ""
        echo "macOS :"
        echo "  brew install mkcert"
        echo ""
        echo "Après installation, exécutez :"
        echo "  mkcert -install"
        echo "  ./manage-stack.sh mkcert"
        echo ""
        return 1
    fi

    log "mkcert est installé, génération des certificats..."

    CERTS_DIR="$SCRIPT_DIR/certs"
    mkdir -p "$CERTS_DIR"

    # Génération des certificats avec tous les domaines
    mkcert -cert-file "$CERTS_DIR/local-cert.pem" -key-file "$CERTS_DIR/local-key.pem" \
        "*.localhost" "*.loc" localhost \
        traefik.localhost portainer.localhost \
        pgadmin.localhost rabbitmq.localhost \
        inbucket.localhost code.localhost \
        swagger.localhost mock.localhost \
        grafana.localhost prometheus.localhost \
        httpbin.localhost \
        127.0.0.1 ::1

    log "Certificats générés avec succès!"

    # Vérification et mise à jour du fichier hosts
    echo ""
    log "Vérification du fichier /etc/hosts..."

    HOSTS_ENTRIES=(
        "traefik.localhost"
        "portainer.localhost"
        "pgadmin.localhost"
        "rabbitmq.localhost"
        "inbucket.localhost"
        "code.localhost"
        "swagger.localhost"
        "mock.localhost"
        "grafana.localhost"
        "prometheus.localhost"
        "httpbin.localhost"
    )

    MISSING_HOSTS=()
    for host in "${HOSTS_ENTRIES[@]}"; do
        if ! grep -q "$host" /etc/hosts; then
            MISSING_HOSTS+=("$host")
        fi
    done

    if [[ ${#MISSING_HOSTS[@]} -gt 0 ]]; then
        warn "Certains domaines manquent dans /etc/hosts"
        echo ""
        echo "Ajoutez ces lignes à votre /etc/hosts :"
        echo ""
        for host in "${MISSING_HOSTS[@]}"; do
            echo "127.0.0.1 $host"
        done
        echo ""
        echo "Commande rapide :"
        echo "sudo tee -a /etc/hosts << EOF"
        for host in "${MISSING_HOSTS[@]}"; do
            echo "127.0.0.1 $host"
        done
        echo "EOF"
    else
        log "Fichier /etc/hosts configuré correctement"
    fi
}

# Main
case "${1:-}" in
    init)
        check_requirements
        create_networks
        generate_certs
        init_configs
        ;;
    start)
        check_requirements
        create_networks
        start_stack
        ;;
    stop)
        stop_stack
        ;;
    restart)
        stop_stack
        sleep 2
        start_stack
        ;;
    status)
        docker-compose -f "$SCRIPT_DIR/traefik/docker-compose.yaml" ps
        docker-compose -f "$SCRIPT_DIR/lamp/docker-compose.yaml" ps
        docker-compose -f "$SCRIPT_DIR/tools/docker-compose.yaml" ps
        ;;
    services)
        show_services
        ;;
    update)
        update_images
        ;;
    mkcert)
        setup_mkcert
        ;;
    cleanup)
        cleanup
        ;;
    logs)
        docker-compose -f "$SCRIPT_DIR/traefik/docker-compose.yaml" logs --tail=50 -f &
        docker-compose -f "$SCRIPT_DIR/lamp/docker-compose.yaml" logs --tail=50 -f &
        docker-compose -f "$SCRIPT_DIR/tools/docker-compose.yaml" logs --tail=50 -f &
        wait
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Commande inconnue: ${1:-}"
        echo ""
        show_help
        exit 1
        ;;
esac
