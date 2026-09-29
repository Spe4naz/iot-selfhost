# MQTT broker (mosquitto) with generated credentials + ACLs.
# On first start deploy/docker/mqtt/docker-entrypoint.sh creates the
# password file from MQTT_* env vars and renders the ACL template.

FROM eclipse-mosquitto:2

USER root

COPY mosquitto.conf /mosquitto/config/mosquitto.conf
COPY acl.template /mosquitto/config/acl.template
COPY docker-entrypoint.sh /usr/local/bin/iot-mosquitto-entrypoint

RUN chmod +x /usr/local/bin/iot-mosquitto-entrypoint \
    && mkdir -p /mosquitto/secrets /mosquitto/data /mosquitto/log

ENTRYPOINT ["/usr/local/bin/iot-mosquitto-entrypoint"]

CMD ["mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]