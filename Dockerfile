FROM mattjenks/centos-ruby:0.1

MAINTAINER Matt Jenks <matt.jenks@gmail.com>

#
# base apache install
#
RUN rpm --rebuilddb \
	&& yum --setopt=tsflags=nodocs -y install \
    httpd \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

#
# Create and populate the install directory
#
# logs in /var/log/https
# www root is /var/www
# serverroot is /etc/httpd
#
RUN mkdir -p -m 750 /var/logs/httpd
COPY var/www/app/vhost.conf /etc/httpd/conf
COPY var/www/app/public_html/index.html /var/www/html

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
# Expose ports
# Apache - 80
#
EXPOSE 80

#
# Start supervisor
#
#CMD /bin/bash
CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]