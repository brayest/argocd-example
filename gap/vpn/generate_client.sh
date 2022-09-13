#!/bin/bash
set -e

# Variables
export AWS_REGION="us-east-1"
export DOMAIN="wearegap.com"
export S3_VPN_BUCKET_NAME="gap-vpn-pki-dev-020663747723-us-east-1-qpsi"
export CLIENT_VPN_ENDPOINT_ID="cvpn-endpoint-06e11763e445d46ea"
export USER="blemus"
export EMAIL="blemus@wearegap.com"	

aws sts get-caller-identity

function download_certificate {
	EASY_RSA_DIR="easy-rsa"
	# git clone https://github.com/OpenVPN/easy-rsa.git ${EASY_RSA_DIR}	
	cd ${EASY_RSA_DIR}/easyrsa3
	aws s3 cp s3://${S3_VPN_BUCKET_NAME}/pki pki/ \
	--region ${AWS_REGION} \
	--recursive
	easyrsa_file=${USER}.vpn.${DOMAIN}.${AWS_REGION}
	if [ -f "${EASY_RSA_DIR}/easyrsa3/pki/reqs/${easyrsa_file}.req" ]; then
		echo "$easyrsa_file already exists."
	else
		./easyrsa \
		build-client-full \
		${easyrsa_file} \
		nopass
	fi	
	if [[ ! -f ./pki/issued/${easyrsa_file}.crt ]]; then
		echo "ERROR: Failed to generate the client certificate for ${user}" >&2
		exit 1
	fi
	cp ./pki/issued/${easyrsa_file}.crt ./
	if [[ ! -f ./pki/private/${easyrsa_file}.key ]]; then
		echo "ERROR: Failed to generate the client key for ${user}" >&2
		exit 1
	fi
	cp ./pki/private/${easyrsa_file}.key ./
	aws ec2 export-client-vpn-client-configuration \
		--client-vpn-endpoint-id ${CLIENT_VPN_ENDPOINT_ID} \
		--region ${AWS_REGION} \
		--output text > client-vpn-connection-config.ovpn && client_vpn_downloaded=true
	if [[ ${client_vpn_downloaded} != "true" ]]; then
		echo "ERROR: Failed to download the VPN endpoint configuration file" >&2
		exit 1
	fi
	cp client-vpn-connection-config.ovpn ${easyrsa_file}.ovpn		
	echo "<cert>" >> ${easyrsa_file}.ovpn
	cat ${easyrsa_file}.crt >> ${easyrsa_file}.ovpn
	echo "</cert>" >> ${easyrsa_file}.ovpn
	rm ${easyrsa_file}.crt
	echo "<key>" >> ${easyrsa_file}.ovpn
	cat ${easyrsa_file}.key >> ${easyrsa_file}.ovpn
	echo "</key>" >> ${easyrsa_file}.ovpn
	rm ${easyrsa_file}.key	
	rm client-vpn-connection-config.ovpn	
	chmod 777 ${easyrsa_file}.ovpn
	echo "VPN Certificate generated: ${easyrsa_file}.ovpn" >&2
    cp ${easyrsa_file}.ovpn ../../
}

download_certificate