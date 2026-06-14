#!/bin/bash
# ============================================================
# KRAAHL WORKSPACE - Script de téléchargement
# Télécharge et prépare le workspace Kan pour Kraahl
# ============================================================
# Usage: bash download.sh [répertoire-cible]

set -e

TARGET_DIR="${1:-/opt/kraahl}"
REPO_URL="https://github.com/kanbn/kan"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

info "Téléchargement du workspace Kraahl vers $TARGET_DIR"

# Créer le répertoire cible
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Méthode 1: Via Docker (recommandée - pas besoin de cloner le repo)
info "Méthode Docker : pull des images officielles..."
docker pull ghcr.io/kanbn/kan:latest
docker pull ghcr.io/kanbn/kan-migrate:latest

# Copier les fichiers de configuration Kraahl
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Copie des fichiers de configuration Kraahl..."

cp "$SCRIPT_DIR/docker-compose.yml" "$TARGET_DIR/docker-compose.yml"
cp "$SCRIPT_DIR/nginx.conf"         "$TARGET_DIR/nginx.conf"
cp "$SCRIPT_DIR/setup.sh"           "$TARGET_DIR/setup.sh"
cp "$SCRIPT_DIR/openvpn-setup.md"   "$TARGET_DIR/openvpn-setup.md"

if [ ! -f "$TARGET_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env.example" "$TARGET_DIR/.env.example"
    cp "$SCRIPT_DIR/.env.example" "$TARGET_DIR/.env"
    # Générer BETTER_AUTH_SECRET automatiquement
    SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    sed -i "s/CHANGE_ME_generate_with_openssl_rand_base64_32/$SECRET/" "$TARGET_DIR/.env"
    info "Fichier .env créé avec secret auto-généré."
fi

chmod +x "$TARGET_DIR/setup.sh"
mkdir -p "$TARGET_DIR/certs"

echo ""
info "============================================="
info "  Kraahl Workspace téléchargé avec succès !"
info "============================================="
echo ""
info "Étapes suivantes:"
info "  1. cd $TARGET_DIR"
info "  2. Éditer .env (configurer NEXT_PUBLIC_BASE_URL, POSTGRES_PASSWORD, etc.)"
info "  3. bash setup.sh"
echo ""
warn "Pour la configuration OpenVPN, voir: $TARGET_DIR/openvpn-setup.md"
