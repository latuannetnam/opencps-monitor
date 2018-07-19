FROM ubuntu:16.04
#Origin: https://github.com/jjethwa/icinga2/blob/master/Dockerfile
LABEL MAINTAINER Le Anh Tuan "latuannetnam@gmail.com"

ENV LANG            en_US.UTF-8
ENV LC_ALL          en_US.UTF-8
ENV APACHE2_HTTP=REDIRECT
ENV ICINGA2_USER_FULLNAME="Icinga2"
    

# Http + Icinga2 port
EXPOSE 80 443 5665

# Utils installatation
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y   apt-utils locales && \
    locale-gen en_US.UTF-8 &&\
    apt-get dist-upgrade -y
    
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    curl unzip \
    apache2 \
    ca-certificates \
    dnsutils \
    gnupg \
    lsb-release \
    mailutils \
    mariadb-client \
    mariadb-server \
    libapache2-mod-php \
    php-curl \
    php-ldap \
    php-mysql \
    procps \
    pwgen \
    snmp \
    ssmtp \
    sudo \
    supervisor \
    wget && \
    apt-get clean all

#Icinga2 installation
RUN export DEBIAN_FRONTEND=noninteractive && \
    wget -O - https://packages.icinga.com/icinga.key | apt-key add - &&\
    echo 'deb https://packages.icinga.com/ubuntu icinga-xenial main' >/etc/apt/sources.list.d/icinga.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    icinga2 \
    icinga2-ido-mysql \
    icingacli \
    icingaweb2 \
    icingaweb2-module-doc \
    icingaweb2-module-monitoring \
    monitoring-plugins \
    # nagios-plugins-contrib \
    # nagios-snmp-plugins \
    && apt-get clean

#Icinga2 Web
RUN mkdir -p /usr/local/share/icingaweb2/modules/

#Custom configuration
ADD assets/ /

# Final fixes
RUN true \
    && sed -i 's/vars\.os.*/vars.os = "Docker"/' /etc/icinga2/conf.d/hosts.conf \
    && mv /etc/icingaweb2/ /etc/icingaweb2.dist \
    && mkdir /etc/icingaweb2 \
    && mv /etc/icinga2/ /etc/icinga2.dist \
    && mkdir /etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && usermod -aG nagios www-data \
    && rm -rf \
       /var/lib/mysql/* \
    && chmod u+s,g+s \
        /bin/ping \
        /bin/ping6 \
        /usr/lib/nagios/plugins/check_icmp

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
