-.PHONY: all

clean:
	rm -rf ca/
	rm -rf certs/
	rm -rf crl/

ca-dir:
	mkdir -p ca/root-ca/private ca/root-ca/db crl certs
	chmod 700 ca/root-ca/private
	cp /dev/null ca/root-ca/db/root-ca.db
	cp /dev/null ca/root-ca/db/root-ca.db.attr
	echo 01 > ca/root-ca/db/root-ca.crt.srl
	echo 01 > ca/root-ca/db/root-ca.crl.srl

root-csr: ca-dir
	openssl req -new \
	-config root-ca.conf \
	-out ca/root-ca.csr \
	-keyout ca/root-ca/private/root-ca.key

root-crt:
	openssl ca -selfsign \
	-config root-ca.conf \
	-in ca/root-ca.csr \
	-out ca/root-ca.crt \
	-extensions root_ca_ext

signing-dir:
	mkdir -p ca/signing-ca/private ca/signing-ca/db crl certs
	cp /dev/null ca/signing-ca/db/signing-ca.db
	cp /dev/null ca/signing-ca/db/signing-ca.db.attr
	echo 01 > ca/signing-ca/db/signing-ca.crt.srl
	echo 01 > ca/signing-ca/db/signing-ca.crl.srl

signing-csr: signing-dir
	openssl req -new \
	-config signing-ca.conf \
	-out ca/signing-ca.csr \
	-keyout ca/signing-ca/private/signing-ca.key

signing-crt:
	openssl ca \
	-config root-ca.conf \
	-in ca/signing-ca.csr \
	-out ca/signing-ca.crt \
	-extensions signing_ca_ext

cheese-csr:
	openssl req -new \
    -config server.conf \
    -out certs/cheese.org.csr \
    -keyout certs/cheese.org.key

cheese-crt:
	openssl ca \
	-config signing-ca.conf \
	-in certs/cheese.org.csr \
	-out certs/cheese.org.crt \
	-extensions server_ext

minimal-crt:
	openssl genrsa -out certs/minimal.key 2048
	openssl req -new -key certs/minimal.key -out certs/minimal.csr
	openssl x509 -req -in certs/minimal.csr -CA ca/signing-ca.crt -CAkey ca/signing-ca/private/signing-ca.key -CAcreateserial -out certs/minimal.crt -days 1024 -sha256

all: clean root-csr root-crt signing-csr signing-crt cheese-csr cheese-crt minimal-crt