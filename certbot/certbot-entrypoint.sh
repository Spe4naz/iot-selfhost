#!/usr/bin/env sh
# Requests the initial Let's Encrypt certificate (webroot challenge served by
# nginx from /var/www/certbot), then loops renewing. The certificate is written
# to the shared `letsencrypt` volume; nginx picks it up via its watcher.
set -e

DOMAIN="${NGINX_DOMAIN:-localhost}"
WEBROOT=/var/www/certbot

issue() {
    if [ -n "${CERTBOT_EMAIL:-}" ]; then
        certbot certonly --webroot -w "$WEBROOT" -d "$DOMAIN" \
            --non-interactive --agree-tos --email "$CERTBOT_EMAIL"
    else
        certbot certonly --webroot -w "$WEBROOT" -d "$DOMAIN" \
            --non-interactive --agree-tos --register-unsafely-without-email
    fi
}

if [ -n "${CERTBOT_EMAIL:-}" ]; then
    echo "[certbot] running for $DOMAIN with $CERTBOT_EMAIL"
else
    echo "[certbot] running for $DOMAIN without contact email"
fi

while :; do
    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "[certbot] certificate missing, requesting..."
        issue && echo "[certbot] certificate issued"
    else
        certbot renew --webroot -w "$WEBROOT" --quiet
    fi
    sleep 43200
done