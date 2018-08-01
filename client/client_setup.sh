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
   echo "Usage: $0 [-h <master hostname>] [-i <master ip address>]" 1>&2; exit 1; 
}

while getopts ":h:i:" opt; do
    case "${opt}" in
        h)
            master_host=${OPTARG}
            ;;
        i)
            master_ip=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${master_host}" ] || [ -z "${master_ip}" ]; then
    usage
fi

echo "master host = ${master_host}"
echo "master ip = ${master_ip}"
echo "client hostname = ${HOSTNAME}"

icinga2 pki save-cert --host ${master_ip} --key /var/lib/icinga2/certs/${HOSTNAME}.key --cert /var/lib/icinga2/certs/${HOSTNAME}.cert --trustedcert /var/lib/icinga2/certs/${master_host}.crt
icinga2 node setup --zone ${HOSTNAME} --parent_host ${master_ip} --endpoint ${master_host},${master_ip} --parent_zone master --cn ${HOSTNAME} --accept-config --accept-commands --disable-confd --trustedcert /var/lib/icinga2/certs/${master_host}.crt
service icinga2 restart

echo "Almost done! Please 1.Enable Liferay monitoring as guided;  2. run script /usr/local/add_client.sh in monitoring server"
