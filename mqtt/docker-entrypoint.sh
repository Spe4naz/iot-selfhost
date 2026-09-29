#!/usr/bin/env sh
# Creates the mosquitto password file and ACL from environment variables on
# the first start (persisted in the mqtt-secrets volume), then re-executes
# the original mosquitto entrypoint command.
set -e

MQTT_USER="${MQTT_USER:-app}"
MQTT_PASSWORD="${MQTT_PASSWORD:-changeme}"
MQTT_DEVICE_USER="${MQTT_DEVICE_USER:-device}"
MQTT_DEVICE_PASSWORD="${MQTT_DEVICE_PASSWORD:-changeme}"

# Ensure mosquitto can write its logs/persistence even if the volume was
# created by the daemon as root.
chown -R mosquitto:mosquitto /mosquitto/data /mosquitto/log 2>/dev/null || true

if [ ! -f /mosquitto/secrets/passwd ]; then
    touch /mosquitto/secrets/passwd
    mosquitto_passwd -b /mosquitto/secrets/passwd "$MQTT_USER" "$MQTT_PASSWORD"
    mosquitto_passwd -b /mosquitto/secrets/passwd "$MQTT_DEVICE_USER" "$MQTT_DEVICE_PASSWORD"
    echo "[mqtt] credentials created for '$MQTT_USER' and '$MQTT_DEVICE_USER'"
fi

sed -e "s|@@APP_USER@@|$MQTT_USER|g" \
    -e "s|@@DEVICE_USER@@|$MQTT_DEVICE_USER|g" \
    /mosquitto/config/acl.template > /mosquitto/secrets/acl

exec "$@"