FROM mattjenks/centos-ruby:0.1

MAINTAINER Matt Jenks <matt.jenks@gmail.com>

#
# base apache install
#
RUN rpm --rebuilddb \
	&& yum --setopt=tsflags=nodocs -y install \
    httpd \
	postgresql \
	postgresql-server \
	postgresql-libs \
	postgresql-contrib \
	postgresql-devel \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

#
# Create and populate the install directory
#
# logs in /var/log/https
# www root is /var/www
# serverroot is /etc/httpd
#
RUN mkdir -p -m 750 /var/log/httpd
COPY var/www/app/vhost.conf /etc/httpd/conf
COPY var/www/app/public_html/index.html /var/www/html

#
# Initialize postgresql database
#     https://docs.docker.com/engine/examples/postgresql_service/
#
RUN service postgresql initdb

#
# Copy files into place
#
ADD etc/apache-bootstrap /etc/
ADD etc/services-config/httpd/apache-bootstrap.conf /etc/services-config/httpd/
ADD etc/services-config/supervisor/supervisord.conf /etc/services-config/supervisor/

RUN mkdir -p /etc/services-config/{httpd/{conf,conf.d},ssl/{certs,private}} \
	&& cp /etc/httpd/conf/httpd.conf /etc/services-config/httpd/conf/ \
	&& ln -sf /etc/services-config/httpd/apache-bootstrap.conf /etc/apache-bootstrap.conf \
	&& ln -sf /etc/services-config/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf \
	&& ln -sf /etc/services-config/ssl/certs/localhost.crt /etc/pki/tls/certs/localhost.crt \
	&& ln -sf /etc/services-config/ssl/private/localhost.key /etc/pki/tls/private/localhost.key \
	&& ln -sf /etc/services-config/supervisor/supervisord.conf /etc/supervisord.conf \
	&& chmod +x /etc/apache-bootstrap

#
# Update postgres settings
#
RUN echo "host all  all    0.0.0.0/0  md5" >> /var/lib/pgsql/data/pg_hba.conf
RUN echo "listen_addresses='*'" >> /var/lib/pgsql/data/postgresql.conf

#
# Update postgres user
#
USER postgres
# TODO this currently does not work because I cant start supervisor as user postgres. This is probably the wrong way
# to go about this anyway as these images are no longer properly layered.
# TODO this is poor as it is a password. Fix this!
RUN /usr/bin/pg_ctl start -l /var/lib/pgsql/data/pg.log -D /var/lib/pgsql/data/ \
   && /bin/sleep 2 \
   && psql --command "ALTER USER postgres WITH ENCRYPTED PASSWORD 'postgres';" template1

#
# Expose ports
# Apache - 80
# postgresql - 5432
#
EXPOSE 80 5432

#
# Expose Volumes
#
VOLUME  ["/var/www", "/var/lib/pgsql/data"]


#
# Start supervisor
#
#CMD /bin/bash
CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]