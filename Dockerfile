FROM httpd:2.4.63

# These variables are inherited from the httpd:alpine image:
# ENV HTTPD_PREFIX /usr/local/apache2
# WORKDIR "$HTTPD_PREFIX"

# Copy in our configuration files.
COPY conf conf/

RUN set -ex;

    # Create empty default DocumentRoot.
RUN mkdir -p "/var/www/html";
    # Create directories for Dav data and lock database.
RUN mkdir -p "/var/lib/dav/data"; \
    touch "/var/lib/dav/DavLock"; \
    chown -R www-data:www-data "/var/lib/dav";

    # Enable DAV modules.
RUN for i in dav dav_fs; do \
        sed -i -e "/^#LoadModule ${i}_module.*/s/^#//" "conf/httpd.conf"; \
    done;

    # Make sure authentication modules are enabled.
RUN for i in authn_core authn_file authz_core authz_user auth_basic auth_digest; do \
        sed -i -e "/^#LoadModule ${i}_module.*/s/^#//" "conf/httpd.conf"; \
    done;

    # Make sure other modules are enabled.
RUN for i in alias headers mime setenvif; do \
        sed -i -e "/^#LoadModule ${i}_module.*/s/^#//" "conf/httpd.conf"; \
    done;

    # Run httpd as "www-data" (instead of "daemon").
RUN for i in User Group; do \
        sed -i -e "s|^$i .*|$i www-data|" "conf/httpd.conf"; \
    done;

    # Include enabled configs and sites.
RUN printf '%s\n' "Include conf/conf-enabled/*.conf" \
        >> "conf/httpd.conf"; \
    printf '%s\n' "Include conf/sites-enabled/*.conf" \
        >> "conf/httpd.conf";

    # Enable dav and default site.
RUN mkdir -p "conf/conf-enabled"; \
    mkdir -p "conf/sites-enabled"; \
    ln -s ../conf-available/dav.conf "conf/conf-enabled"; \
    ln -s ../sites-available/default.conf "conf/sites-enabled";

    # Install openssl if we need to generate a self-signed certificate.
RUN apt-get install openssl

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
EXPOSE 80/tcp 443/tcp
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "httpd-foreground" ]

LABEL \
  apache2.version="2.4.58"
