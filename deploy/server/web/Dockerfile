FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apache2 ca-certificates curl php-cgi libqt5gui5 libqt5network5 \
        libgl1 libglu1-mesa libopenal1 libqt5opengl5 libqt5sql5-psql libsdl2-2.0-0 util-linux \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod cgid actions env \
    && a2disconf serve-cgi-bin \
    && a2dissite 000-default \
    && useradd --create-home --uid 1000 --shell /bin/bash openshores \
    && install -d /opt/openshores/www /opt/openshores/cgi-bin /opt/openshores/bin /opt/openshores/lib \
    && ln -s /usr/bin/php-cgi /opt/openshores/cgi-bin/php \
    && install -d -o 1000 -g 1000 /var/lib/openshores/reports

COPY openshores.conf /etc/apache2/sites-available/openshores.conf
COPY index.php server-status.php server-status.js playerson.php galactic.php styles.css /opt/openshores/www/
COPY images/ /opt/openshores/www/images/
COPY register.html reset.html emailchange.html passchange.html /opt/openshores/www/
COPY health.cgi /opt/openshores/cgi-bin/health.cgi
COPY entrypoint.sh /usr/local/bin/openshores-web
COPY bin/AuServerStatus /opt/openshores/bin/AuServerStatus
COPY bin/AuEmpireReport /opt/openshores/bin/AuEmpireReport
COPY lib/ /opt/openshores/lib/
COPY generate-standings.sh /opt/openshores/bin/generate-standings
COPY generate-avatars.sh /opt/openshores/bin/generate-avatars
COPY report-scheduler.sh /opt/openshores/bin/report-scheduler
COPY bin/AuAcctNew bin/AuAcctEmail bin/AuAcctPassword /opt/openshores/cgi-bin/

RUN chmod 0755 /usr/local/bin/openshores-web /opt/openshores/bin/AuServerStatus \
        /opt/openshores/bin/AuEmpireReport /opt/openshores/bin/generate-standings \
        /opt/openshores/bin/generate-avatars \
        /opt/openshores/bin/report-scheduler \
        /opt/openshores/cgi-bin/health.cgi /opt/openshores/cgi-bin/AuAcct* \
    && a2ensite openshores \
    && php-cgi -l /opt/openshores/www/index.php \
    && php-cgi -l /opt/openshores/www/server-status.php \
    && php-cgi -l /opt/openshores/www/playerson.php \
    && php-cgi -l /opt/openshores/www/galactic.php \
    && apache2ctl -t

EXPOSE 80
STOPSIGNAL SIGWINCH
ENTRYPOINT ["/usr/local/bin/openshores-web"]
