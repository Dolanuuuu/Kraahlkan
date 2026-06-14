# Kraahl - Intégration OpenVPN

## Architecture

```
Internet
    │
    ▼
[OpenVPN Server] ──── 10.8.0.0/24
    │
    ├── 10.8.0.1  ← Serveur Kraahl (kan.kraahl.com)
    │                  ├── kraahl-nginx   (port 80/443/8080)
    │                  ├── kraahl-web     (port 3000, interne)
    │                  └── kraahl-db      (port 5432, interne)
    │
    └── 10.8.0.x  ← Clients VPN (équipe Kraahl)
```

## Installation OpenVPN (Ubuntu/Debian)

```bash
# Installation rapide avec le script officiel
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
bash openvpn-install.sh
```

## Sécurisation de Kan derrière VPN

Dans `nginx.conf`, décommenter les lignes de restriction IP :

```nginx
# Dans le bloc server HTTPS (port 443)
allow 10.8.0.0/24;   # Réseau OpenVPN
allow 127.0.0.1;     # Localhost
deny all;
```

## Ajouter un client VPN (membre de l'équipe)

```bash
# Lancer le script d'installation et choisir "Add a new client"
bash openvpn-install.sh

# Le fichier .ovpn sera créé
# Envoyer le fichier .ovpn au membre de l'équipe de manière sécurisée
```

## Accès au workspace depuis VPN

Une fois connecté au VPN Kraahl :
- **Interface web**: http://10.8.0.1:8080 ou https://kan.kraahl.com
- **Connexion**: Créer un compte sur la page d'accueil

## Ports utilisés

| Port | Service         | Accès          |
|------|-----------------|----------------|
| 80   | HTTP redirect   | Public          |
| 443  | HTTPS (Kan UI)  | Public ou VPN   |
| 8080 | HTTP (Kan UI)   | VPN uniquement  |
| 1194 | OpenVPN         | Public (UDP)    |
| 3000 | Next.js (int.)  | Interne Docker  |
| 5432 | PostgreSQL      | Interne Docker  |

## Firewall (ufw)

```bash
ufw allow 22/tcp        # SSH
ufw allow 80/tcp        # HTTP
ufw allow 443/tcp       # HTTPS
ufw allow 1194/udp      # OpenVPN
ufw enable
```

## Génération des certificats SSL (optionnel)

Si vous avez un domaine public pointant vers le serveur :

```bash
apt install certbot -y
certbot certonly --standalone -d kan.kraahl.com
cp /etc/letsencrypt/live/kan.kraahl.com/fullchain.pem kraahl/certs/
cp /etc/letsencrypt/live/kan.kraahl.com/privkey.pem kraahl/certs/
```
