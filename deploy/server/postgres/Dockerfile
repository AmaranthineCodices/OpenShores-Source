FROM postgres:14-bookworm

COPY deploy/server/postgres/init.sh /docker-entrypoint-initdb.d/10-openshores.sh
COPY shell.scripts/initlogin.sql /opt/openshores/sql/initlogin.sql
COPY shell.scripts/initmail.sql /opt/openshores/sql/initmail.sql
COPY shell.scripts/inituniverse.sql /opt/openshores/sql/inituniverse.sql
COPY shell.scripts/initstatic.sql /opt/openshores/sql/initstatic.sql

RUN chmod 0755 /docker-entrypoint-initdb.d/10-openshores.sh
