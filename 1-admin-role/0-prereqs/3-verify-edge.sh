#!/bin/bash

CERT_FILE=conjur-edge.crt

echo "Getting listing of webservice endpoints from Edge node..."
../../bin/ccedge-cli.sh listws
echo
echo "Verify web service listing looks correct."
echo
read -n 1 -s -r -p "Press any key to continue"
echo "Getting cert from Edge node..."
openssl s_client -connect localhost:443 -showcerts </dev/null 2>/dev/null	\
  | openssl x509 -in /dev/stdin -outform PEM					\
  > $CERT_FILE
openssl x509 -in $CERT_FILE -text -noout
echo
echo "Verify that there is a DNS entry under 'X509v3 Subject Alternative Name:'"
echo "  that contains 'host.docker.internal'"
echo
rm $CERT_FILE
