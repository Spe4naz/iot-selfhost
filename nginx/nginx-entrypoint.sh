#!/usr/bin/env bash
# Renders the nginx vhosts from templates and starts nginx.
#
# Modes:
#   NGINX_TLS=0 -> HTTP-only vhost (http-plain.conf.template)
#   NGINX_TLS=1 -> ACME vhost on :80 + HTTPS vhost, but the HTTPS vhost is
#                  generated ONLY after the certificate appears in
#                  /etc/letsencrypt/live/${NGINX_DOMAIN}/ (written by certbot).
#
# Background watchers:
#   1) enable the HTTPS vhost as soon as certbot publishes the first cert;
#   2) reload nginx hourly so renewed certificates are picked up.
set -euo pipefail

export NGINX_DOMAIN="${NGINX_DOMAIN:-localhost}"
export UPSTREAM_SERVER="${UPSTREAM_SERVER:-server}"
export NGINX_TLS="${NGINX_TLS:-0}"

TEMPLATES=/etc/nginx/templates
CONFD=/etc/nginx/conf.d
CERT_FILE="/etc/letsencrypt/live/${NGINX_DOMAIN}/fullchain.pem"
SUBST='${NGINX_DOMAIN} ${UPSTREAM_SERVER}'

if [ "$NGINX_TLS" = "1" ]; then
    envsubst "$SUBST" < "$TEMPLATES/http-acme.conf.template" > "$CONFD/00-http.conf"
    if [ -f "$CERT_FILE" ]; then
        envsubst "$SUBST" < "$TEMPLATES/ssl.conf.template" > "$CONFD/10-ssl.conf"
        echo "[nginx] TLS enabled with existing certificate"
    else
        echo "[nginx] TLS requested, awaiting first certificate from certbot"
    fi
else
    envsubst "$SUBST" < "$TEMPLATES/http-plain.conf.template" > "$CONFD/00-http.conf"
fi

(
    while :; do
        if [ "$NGINX_TLS" = "1" ] && [ -f "$CERT_FILE" ] && [ ! -f "$CONFD/10-ssl.conf" ]; then
            envsubst "$SUBST" < "$TEMPLATES/ssl.conf.template" > "$CONFD/10-ssl.conf"
            echo "[nginx] certificate found, enabling HTTPS"
            nginx -s reload 2>/dev/null || true
        fi
        sleep 60
    done
) &

(
    while :; do
        sleep 3600
        nginx -s reload 2>/dev/null || true
    done
) &

exec nginx -g 'daemon off;'