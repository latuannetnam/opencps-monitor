#!/bin/bash
#latuannetnam@gmail.com

DIR="`pwd`"
HOSTNAME=`hostname`
if [[ $EUID -ne 0 ]]; then
 echo "You are not running with root permission. Please chage to root to install required packages"
 exit 1
fi
usage() 
{ 
   echo "Usage: $0 [-h <client hostname>] [-i <client ip address>] [-o <Ubuntu|CentOS>]" 1>&2; exit 1; 
}

while getopts ":h:i:o:" opt; do
    case "${opt}" in
        h)
            client_host=${OPTARG}
            ;;
        i)
            client_ip=${OPTARG}
            ;;
        o)  
	    os_type=${OPTARG}
            if [ ${os_type} != "Ubuntu" ] && [ ${os_type} != "CentOS" ]; then
		 usage
	    fi	
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${client_host}" ] || [ -z "${client_ip}" ] || [ -z "${os_type}" ]; then
    usage
fi

echo "client host = ${client_host} client ip = ${client_ip} os_type = ${os_type}"
echo "master hostname = ${HOSTNAME}"

# Sign cerfitification request for client
finger_print=`icinga2 ca list | grep  ${client_host} | awk '{print $1} '` 
echo "Finger print = ${finger_print}"
icinga2 ca sign ${finger_print}

#Create host configuration 
if [ -f /etc/icinga2/zones.d/master/${client_host}.conf ]; then
  echo "Configuration file ${client_host}.conf is already exists. No action!"
  exit 0
fi
	
cat > /etc/icinga2/zones.d/master/${client_host}.conf <<-END
object Endpoint "${client_host}" {
}

object Zone "${client_host}" {
        endpoints = ["${client_host}"]
        parent = "master" //establish zone hierarchy
}

/* Host command for */
object Host "${client_host}" {
  /* Import the default host template defined in templates.conf. */
  import "generic-client-host-linux"
  vars.client_endpoint = name
  vars.os_type="${os_type}"
  //vars.os_type="CentOS"
  address = "${client_ip}"
  vars.ping6 = "no"
  vars.server_types= ["Linux", "MySQL", "JMX", "Tomcat", "Liferay", "OpenCPS"]
  vars.partition = "sda*"
  //vars.geolocation = GeoLocation.LOC_NetNamHN
  //vars.ssh_port       = 22
  //http
  //vars.http_vhost="${client_host}"
  //vars.http_extendedperfdata = true
  //vars.apache_status_port = 8081
  //proc
  vars.procs_warning = 500
  vars.procs_critical = 700
  //vmsat_proc
  vars.vmstat_procs_warning = 550
  vars.vmstat_procs_critical = 700
  //load
  vars.load_wload1 = 10
  vars.load_cload1 = 20
  vars.load_wload5 = 10
  vars.load_cload5 = 20
  vars.load_wload15 = 10
  vars.load_cload15 = 20
  // check_mysql
  vars.mysql_username = "opencps"
  vars.mysql_password = "netnam"
  vars.mysql_hostname = "127.0.0.1"
  // check_mysql_query
  vars.mysql_sqls["_max_query_time"] = {
        mysql_query_execute = "SELECT max(TIME) FROM INFORMATION_SCHEMA.PROCESSLIST where command<>'Sleep'"
        mysql_query_username = "opencps"
        mysql_query_password = "netnam"
        mysql_query_hostname = "127.0.0.1"
  }

  vars.mysql_sqls["_long_queries"] = {
        mysql_query_execute = "SELECT count(*) FROM INFORMATION_SCHEMA.PROCESSLIST where time>30 AND command<>'Sleep'"
        mysql_query_username = "opencps"
        mysql_query_password = "netnam"
        mysql_query_hostname = "127.0.0.1"
  }

}
END

eval "icinga2 daemon -C"
result=$?
#echo "Result = ${result}"
if [ ${result} != 0 ]; then
  echo "Error with configuration file. Please fix"
  exit 1
fi	

service icinga2 reload
echo "Done!"

