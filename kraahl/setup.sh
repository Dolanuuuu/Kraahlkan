#!/bin/bash
# ============================================================
# KRAAHL WORKSPACE - Script de setup automatique
# ============================================================
# Usage: bash setup.sh

set -e

KRAAHL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "  ██╗  ██╗██████╗  █████╗  █████╗ ██╗  ██╗██╗     "
echo "  ██║ ██╔╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██║     "
echo "  █████╔╝ ██████╔╝███████║███████║███████║██║     "
echo "  ██╔═██╗ ██╔══██╗██╔══██║██╔══██║██╔══██║██║     "
echo "  ██║  ██╗██║  ██║██║  ██║██║  ██║██║  ██║███████╗"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝"
echo ""
echo "  Workspace KAN - Setup Script"
echo ""

# Vérifier Docker
command -v docker >/dev/null 2>&1 || error "Docker n'est pas installé. Installer Docker d'abord."
command -v docker compose >/dev/null 2>&1 || error "Docker Compose n'est pas installé."

cd "$KRAAHL_DIR"

# Créer .env si inexistant
if [ ! -f ".env" ]; then
    info "Création du fichier .env depuis le template..."
    cp .env.example .env

    # Générer automatiquement BETTER_AUTH_SECRET
    if command -v openssl >/dev/null 2>&1; then
        SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
        sed -i "s/CHANGE_ME_generate_with_openssl_rand_base64_32/$SECRET/" .env
        info "BETTER_AUTH_SECRET généré automatiquement."
    fi

    warn "Fichier .env créé. Veuillez le configurer avant de continuer."
    warn "Notamment: NEXT_PUBLIC_BASE_URL et POSTGRES_PASSWORD"
    echo ""
    read -p "Appuyez sur Entrée une fois le fichier .env configuré..."
fi

# Charger les variables d'env
set -a; source .env; set +a

# Valider les variables requises
[ -z "$NEXT_PUBLIC_BASE_URL" ] && error "NEXT_PUBLIC_BASE_URL est requis dans .env"
[ -z "$BETTER_AUTH_SECRET" ] && error "BETTER_AUTH_SECRET est requis dans .env"
[ -z "$POSTGRES_PASSWORD" ] && error "POSTGRES_PASSWORD est requis dans .env"

info "Configuration validée."

# Télécharger les images Docker
info "Téléchargement des images Docker (kan:latest)..."
docker pull ghcr.io/kanbn/kan:latest
docker pull ghcr.io/kanbn/kan-migrate:latest
docker pull postgres:15
docker pull nginx:alpine

info "Images téléchargées avec succès."

# Créer les répertoires nécessaires
mkdir -p certs

# Vérifier les certificats SSL
if [ ! -f "certs/fullchain.pem" ] || [ ! -f "certs/privkey.pem" ]; then
    warn "Certificats SSL non trouvés dans ./certs/"
    warn "Pour un accès HTTPS, placez vos certificats dans:"
    warn "  - kraahl/certs/fullchain.pem"
    warn "  - kraahl/certs/privkey.pem"
    warn ""
    warn "Pour générer avec Let's Encrypt (nécessite un domaine public):"
    warn "  certbot certonly --standalone -d kan.kraahl.com"
    warn ""
    warn "Pour accès VPN uniquement (sans HTTPS), le port 8080 est disponible."
fi

# Démarrer les services
info "Démarrage des services Kraahl..."
docker compose up -d

# Attendre que la migration se termine
info "Attente de la migration de base de données..."
timeout 120 docker compose wait migrate 2>/dev/null || true

# Vérifier l'état
info "Vérification de l'état des services..."
sleep 3
docker compose ps

echo ""
info "============================================="
info "  Kraahl Workspace est démarré !"
info "============================================="
echo ""
info "  URL locale:  http://localhost:${WEB_PORT:-3000}"
info "  URL VPN:     http://10.8.0.1:8080 (si VPN configuré)"
[ -f "certs/fullchain.pem" ] && info "  URL HTTPS:   $NEXT_PUBLIC_BASE_URL"
echo ""
info "  Logs: docker compose logs -f"
info "  Stop: docker compose down"
echo ""
