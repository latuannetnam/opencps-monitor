#!/bin/bash
#latuannetnam@gmail.com

DIR="`pwd`"
HOSTNAME=`hostname`
if [[ $EUID -ne 0 ]]; then
 echo "You are not running with root permission. Please chage to root to install required packages"
 exit 1
fi
echo "Checking Linux platform"
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
else
    echo "Could not determine distribution. Exit"
    exit 1
fi

echo "OS: $OS. Version: $VER"
echo "Installing package"
if [ $OS == "ubuntu" ]; then
    echo "Ubuntu OS"
    if [ $VER != "16.04" ]; then
       echo "Not supported Ubuntu distro. Exiting"
       exit 1
    fi
    ### Installing utils
    apt-get update
    apt-get upgrade -y
    apt-get install -y --no-install-recommends \
      apt-utils \
      ca-certificates \
      curl \
      dnsutils \
      gnupg \
      locales \
      lsb-release \
      mailutils \
      procps \
      pwgen \
      sudo \
      unzip \
      wget \
      nano mc git \
      apt-transport-https
    ### Installing icinga2
    curl -s https://packages.icinga.com/icinga.key | apt-key add -
    echo "deb https://packages.icinga.com/ubuntu icinga-xenial main" > /etc/apt/sources.list.d/icinga.list
    apt-get update
    apt-get install -y --no-install-recommends \
      icinga2 \
      monitoring-plugins \
      nagios-plugins-contrib \
      nagios-snmp-plugins
    ### Installing Centreon plugin
    if [ ! -d "/usr/lib/nagios/plugins/thirdparty/centreon-plugins" ]; then
   	echo "Installing centrons plugins"
	apt-get install -y \
       		perl libsnmp-perl libxml-libxml-perl \
       		libjson-perl libwww-perl libxml-xpath-perl \
       		libnet-telnet-perl libnet-ntp-perl libnet-dns-perl \
       		libdbi-perl libdbd-mysql-perl libdbd-pg-perl
    	cpan App::cpanminus
    	cpanm Pod::Find
    	mkdir -p /usr/lib/nagios/plugins/thirdparty
    	cd /usr/lib/nagios/plugins/thirdparty
    	git clone https://github.com/centreon/centreon-plugins.git
    	cd /usr/lib/nagios/plugins/thirdparty/centreon-plugins
    	chmod +x centreon_plugins.pl
    	mkdir -p /var/lib/centreon/centplugins
    	chown -R nagios.nagios /var/lib/centreon/
     fi
    ### Test centreon pluing
    /usr/lib/nagios/plugins/thirdparty/centreon-plugins/centreon_plugins.pl --plugin os::linux::local::plugin --mode memory
    ### Installing other plugins
    # check_linux_stat plugin
    cd /usr/lib/nagios/plugins
    if [ ! -f "/usr/lib/nagios/plugins/check_linux_stats.pl" ]; then
    	echo "Installing check_linux_stats.pl"
    	cpanm Sys::Statistics::Linux
    	wget "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=2516&cf_id=24" -O check_linux_stats.pl
    	chmod +x check_linux_stats.pl
    fi
    # check_cpu_procs plugin
    if [ ! -f "/usr/lib/nagios/plugins/check_cpu_proc.sh" ]; then
        echo "Installing check_cpu_proc.sh"
    	wget https://raw.githubusercontent.com/thomasweaver/check_cpu_proc/master/check_cpu_proc.sh
    	chmod +x check_cpu_proc.sh
    fi
    # check_jmx plugin
    if [ ! -d "/usr/lib/nagios/plugins/thirdparty/nagios-jmx-plugin" ]; then
   	echo "Installing check_jmx"
    	apt-get install -y  dos2unix
    	cd /usr/lib/nagios/plugins/thirdparty
    	wget http://snippets.syabru.ch/nagios-jmx-plugin/download/nagios-jmx-plugin.zip
   	unzip nagios-jmx-plugin.zip
    	ln -s nagios-jmx-plugin-1.2.3 nagios-jmx-plugin
    	cd nagios-jmx-plugin
    	dos2unix check_jmx
    	chmod +x check_jmx
    fi
    #### End of Ubuntu installation

elif [ $OS == "centos" ]; then
   echo "CentOS OS"
   if [ $VER != "6" ] && [ $VER != "7" ]; then
     echo "Not support distribution. Exiting!"
     exit 1
   fi
   yum -y install epel-release
   
   ### Installing icinga2
   if [ $VER == "6" ]; then
      yum install -y https://packages.icinga.com/epel/icinga-rpm-release-6-latest.noarch.rpm
   else
      yum install https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm	
   fi 
   yum install -y icinga2
   yum install -y nagios-plugins-all
   mkdir /usr/lib/nagios
   ln -s /usr/lib64/nagios/plugins /usr/lib/nagios/plugins
   
   ### installing Centrenon plugin
   if [ ! -d "/usr/lib/nagios/plugins/thirdparty/centreon-plugins" ]; then
        echo "Installing centrons plugins"
   	yum install -y git
   	yum install -y  \
		perl net-snmp-perl \
		perl-XML-LibXML \
		perl-JSON perl-libwww-perl \
        	perl-XML-XPath perl-Net-Telnet \
		perl-Net-DNS perl-DBI perl-DBD-MySQL \
  		perl-DBD-Pg perl-CPAN
	cpan App::cpanminus
	cpanm Pod::Find
	mkdir -p /usr/lib/nagios/plugins/thirdparty
	mkdir -p /var/lib/centreon/centplugins
	if [ $VER == "6" ]; then
		chown -R nagios.nagios /var/lib/centreon/
	else
		chown -R icinga.icinga /var/lib/centreon/
	fi	
	cd /usr/lib/nagios/plugins/thirdparty
	git clone https://github.com/centreon/centreon-plugins.git
	cd /usr/lib/nagios/plugins/thirdparty/centreon-plugins
	chmod +x centreon_plugins.pl
   fi
   ### Test centreon pluing
   /usr/lib/nagios/plugins/thirdparty/centreon-plugins/centreon_plugins.pl --plugin os::linux::local::plugin --mode memory
   ### Installing other plugins
   # check_linux_stat plugin
   cd /usr/lib/nagios/plugins
   if [ ! -f "/usr/lib/nagios/plugins/check_linux_stats.pl" ]; then
       	echo "Installing check_linux_stats.pl"
        cpanm Sys::Statistics::Linux
        wget "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=2516&cf_id=24" -O check_linux_stats.pl
        chmod +x check_linux_stats.pl
   fi
   # check_cpu_procs plugin
   if [ ! -f "/usr/lib/nagios/plugins/check_cpu_proc.sh" ]; then
       	echo "Installing check_cpu_proc.sh"
        wget https://raw.githubusercontent.com/thomasweaver/check_cpu_proc/master/check_cpu_proc.sh
        chmod +x check_cpu_proc.sh
   fi
   # check_jmx plugin
   if [ ! -d "/usr/lib/nagios/plugins/thirdparty/nagios-jmx-plugin" ]; then
        echo "Installing check_jmx"
        yum install -y  dos2unix
        cd /usr/lib/nagios/plugins/thirdparty
        wget http://snippets.syabru.ch/nagios-jmx-plugin/download/nagios-jmx-plugin.zip
        unzip nagios-jmx-plugin.zip
        ln -s nagios-jmx-plugin-1.2.3 nagios-jmx-plugin
        cd nagios-jmx-plugin
        dos2unix check_jmx
        chmod +x check_jmx
   fi
   #### End of CentOS installation

fi

