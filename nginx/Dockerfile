# nginx for the self-hosted stack.
# envsubst renders the templates (see nginx-entrypoint.sh). The site content
# (static page + /fw OTA artifacts) is bind-mounted from deploy/site.

FROM nginx:1.27-alpine

RUN apk add --no-cache gettext bash

COPY conf/http-plain.conf.template /etc/nginx/templates/http-plain.conf.template
COPY conf/http-acme.conf.template /etc/nginx/templates/http-acme.conf.template
COPY conf/ssl.conf.template /etc/nginx/templates/ssl.conf.template
COPY nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint

RUN chmod +x /usr/local/bin/nginx-entrypoint

ENTRYPOINT ["/usr/local/bin/nginx-entrypoint"]