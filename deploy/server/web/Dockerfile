FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2 ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod cgid \
    && a2disconf serve-cgi-bin \
    && a2dissite 000-default \
    && install -d /opt/openshores/www /opt/openshores/cgi-bin \
    && install -d -o 1000 -g 1000 /var/lib/openshores/reports

COPY openshores.conf /etc/apache2/sites-available/openshores.conf
COPY index.html /opt/openshores/www/index.html
COPY health.cgi /opt/openshores/cgi-bin/health.cgi
COPY entrypoint.sh /usr/local/bin/openshores-web

RUN chmod 0755 /usr/local/bin/openshores-web /opt/openshores/cgi-bin/health.cgi \
    && a2ensite openshores \
    && apache2ctl -t

EXPOSE 80
STOPSIGNAL SIGWINCH
ENTRYPOINT ["/usr/local/bin/openshores-web"]
