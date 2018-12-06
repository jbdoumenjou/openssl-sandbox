From https://media.readthedocs.org/pdf/pki-tutorial/latest/pki-tutorial.pdf

# Goal

The main goal is to play with openssl configuration to fill the certificates and check how it works.

# Usage

```bash
make all 
```

It will generate directories and csr/cert.
You will be prompt to define and use a passphrase and to fill the certificate form.
For more details, see the Makefile.

# Create Root CA

## Create directories

```bash
mkdir -p ca/root-ca/private ca/root-ca/db crl certs
chmod 700 ca/root-ca/private
```

The ca directory holds CA resources, the crl directory holds CRLs, and the certs directory holds user certificates.

## Create database

```bash
cp /dev/null ca/root-ca/db/root-ca.db
cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl
echo 01 > ca/root-ca/db/root-ca.crl.srl
```

The database files must exist before the openssl ca command can be used.

## Create CA Request

CSR + private key

```bash
openssl req -new \
-config root-ca.conf \
-out ca/root-ca.csr \
-keyout ca/root-ca/private/root-ca.key
```

With the openssl req -new command we create a private key and a certificate signing request (CSR) for the root CA.
You will be asked for a passphrase to protect the private key.
The openssl req command takes its configuration from the [req] section of the configuration file.

   
## Create CA certificate

```bash
openssl ca -selfsign \
-config root-ca.conf \
-in ca/root-ca.csr \
-out ca/root-ca.crt \
-extensions root_ca_ext
```

With the openssl ca command we issue a root CA certificate based on the CSR. The root certificate is selfsigned
and serves as the starting point for all trust relationships in the PKI. The openssl ca command takes its
configuration from the [ca] section of the configuration file.

# Create Signing CA

## Create directories

```bash
mkdir -p ca/signing-ca/private ca/signing-ca/db crl certs
```
The ca directory holds CA resources, the crl directory holds CRLs, and the certs directory holds user certificates.

## Create database

```bash
cp /dev/null ca/signing-ca/db/signing-ca.db
cp /dev/null ca/signing-ca/db/signing-ca.db.attr
echo 01 > ca/signing-ca/db/signing-ca.crt.srl
echo 01 > ca/signing-ca/db/signing-ca.crl.srl
```

## Create CA request

```bash
openssl req -new \
-config signing-ca.conf \
-out ca/signing-ca.csr \
-keyout ca/signing-ca/private/signing-ca.key
```

With the openssl req -new command we create a private key and a CSR for the signing CA. You will be asked
for a passphrase to protect the private key. The openssl req command takes its configuration from the [req] section
of the configuration file.

## Create CA certificate

```bash
openssl ca \
-config root-ca.conf \
-in ca/signing-ca.csr \
-out ca/signing-ca.crt \
-extensions signing_ca_ext
```

With the openssl ca command we issue a certificate based on the CSR. The command takes its configuration from
the [ca] section of the configuration file. Note that it is the root CA that issues the signing CA certificate! Note also
that we attach a different set of extensions.


# Operate signing CA

## Create server certificate

```bash
openssl req -new \
-config server.conf \
-out certs/cheese.org.csr \
-keyout certs/cheese.org.key
```

## Create TLS server certificate

```bash
openssl ca \
-config signing-ca.conf \
-in certs/cheese.org.csr \
-out certs/cheese.org.crt \
-extensions server_ext
```
Next we create the private key and CSR for a TLS-server certificate using another request configuration file.
When prompted enter these DN components: DC=com, DC=cheese, O=Cheese, CN=*.cheese.org.


## Create a minimal certificate

```bash
openssl genrsa -out certs/minimal.key 2048
openssl req -new -key certs/minimal.key -out certs/minimal.csr
openssl x509 -req -in certs/minimal.csr -CA ca/signing-ca.crt -CAkey ca/signing-ca/private/signing-ca.key -CAcreateserial -out certs/minimal.crt -days 1024 -sha256                   
```


# Notes

The domain component must be the same through the differente configurations.

# Glossary

* **Public Key Infrastructure (PKI)**: Security architecture where trust is conveyed through the signature of a trusted
CA.
* **Certificate Authority (CA)**: Entity issuing certificates and CRLs.
* **Registration Authority (RA)**: Entity handling PKI enrollment. May be identical with the CA.
* **Certificate**: Public key and ID bound by a CA signature.
* **Certificate Signing Request (CSR)** Request for certification. Contains public key and ID to be certified.
* **Certificate Revocation List (CRL)** List of revoked certificates. Issued by a CA at regular intervals.
* **Certification Practice Statement (CPS)** Document describing structure and processes of a CA.
* **Root CA**: CA at the root of a PKI hierarchy. Issues only CA certificates.
* **Intermediate CA**: CA below the root CA but not a signing CA. Issues only CA certificates.
* **Signing CA**: CA at the bottom of a PKI hierarchy. Issues only user certificates.
* **CA Certificate**: Certificate of a CA. Used to sign certificates and CRLs.
* **Root Certificate**: Self-signed CA certificate at the root of a PKI hierarchy. Serves as the PKI’s trust anchor.
* **Cross Certificate CA**: certificate issued by a CA external to the primary PKI hierarchy. Used to connect two PKIs
and thus usually comes in pairs. 1
* **User Certificate**: End-user certificate issued for one or more purposes: email-protection, server-auth, client-auth,
code-signing, etc. A user certificate cannot sign other certificates.
* **Privacy Enhanced Mail (PEM)**: Text format. Base-64 encoded data with header and footer lines. Preferred format
in OpenSSL and most software based on it (e.g. Apache mod_ssl, stunnel).
* **Distinguished Encoding Rules (DER)**: Binary format. Preferred format in Wind