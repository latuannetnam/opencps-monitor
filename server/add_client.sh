#!/bin/bash
#latuannetnam@gmail.com
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

docker-compose exec icinga2 /usr/local/bin/add_client.sh -h ${client_host} -i ${client_ip} -o ${os_type}