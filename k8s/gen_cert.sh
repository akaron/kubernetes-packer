export KEY_FILE=my-prometheus.key
export CERT_FILE=my-prometheus.cert
export CERT_NAME=prometheus-tls
export HOST=prometheus.localhost
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=${HOST}/O=${HOST}"
kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE}

