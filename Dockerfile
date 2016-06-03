FROM centos:centos6.7

MAINTAINER Matt Jenks <matt.jenks@gmail.com>

#
# Import the RPM GPG keys for Repositories
#
RUN rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6 \
	&& rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6 \
	&& rpm --import https://dl.iuscommunity.org/pub/ius/IUS-COMMUNITY-GPG-KEY

#
# Build base OS
#
RUN rpm --rebuilddb \
	&& yum -y install \
	centos-release-scl \
	centos-release-scl-rh \
	epel-release \
	https://centos6.iuscommunity.org/ius-release.rpm \
	python-setuptools-0.6.10-3.el6 \
	which \
	tar \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

#
# Install supervisord (required to run more than a single process in a container)
# Note: EPEL package lacks /usr/bin/pidproxy
# We require supervisor-stdout to allow output of services started by
# supervisord to be easily inspected with "docker logs".
#
RUN easy_install 'supervisor == 3.2.3' 'supervisor-stdout == 0.1.1' \
	&& mkdir -p /var/log/supervisor/

#
# UTC Timezone & Networking
#
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
	&& echo "NETWORKING=yes" > /etc/sysconfig/network


#
# Copy files into place
#
ADD etc/services-config/supervisor/supervisord.conf /etc/services-config/supervisor/

RUN mkdir -p /etc/supervisord.d/ \
	&& ln -sf /etc/services-config/supervisor/supervisord.conf /etc/supervisord.conf

#
# instal rvm, ruby, bundler
#
RUN gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN curl -L get.rvm.io | bash -s stable
RUN source /etc/profile.d/rvm.sh
RUN /bin/bash -l -c "rvm requirements && rvm cleanup all && yum clean all"
RUN /bin/bash -l -c "rvm install --default ruby-2.1.3 && rvm cleanup all && gem cleanup"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

#
# Purge
#
RUN rm -rf /etc/ld.so.cache \
	; rm -rf /sbin/sln \
	; rm -rf /usr/{{lib,share}/locale,share/{man,doc,info,gnome/help,cracklib,il8n},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
	; rm -rf /{root,tmp,var/cache/{ldconfig,yum}}/* \
	; > /etc/sysconfig/i18n

#
# Set default environment variables
#

#
# Start supervisor
#
#CMD /bin/bash
CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]