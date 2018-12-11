[![](https://images.microbadger.com/badges/version/jefferyb/shibboleth-sp.svg)](http://microbadger.com/images/jefferyb/shibboleth-sp "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/jefferyb/shibboleth-sp.svg)](http://microbadger.com/images/jefferyb/shibboleth-sp "Get your own image badge on microbadger.com")

## jefferyb/shibboleth-sp
A Shibboleth Service Provider (SP). Just put this in front a service that you would like to protect, working as a Reverse-Proxy

## Supported tags
-	[`latest` (*Dockerfile*)](https://github.com/jefferyb/docker-shibboleth-sp/blob/master/Dockerfile)

## VARIABLES
- **HOSTNAME** : *(default: "localhost")*

### APACHE SECTION
- **SERVICE_TO_PROTECT** : *(default: "localhost")*
- **SERVICE_PORT** : *(default: "80")*

### SHIBBOLETH SECTION
- **IDP_ENTITY_ID** : *(default: "https://samltest.id/saml/idp")*
- **IDP_METADATA_URL** : *(default: "https://samltest.id/saml/idp")*
- **SUPPORT_EMAIL** : *(default: 'root@localhost')*
- **SHIB_METADATA_BACKUP_URL** : *(default: "https://samltest.id/saml/idp")*
- **SHIB_DOWNLOAD_METADATA** : *(default: true)*

## Port
- **80**.
- **443**.

## Setup
### Apache Certificates

* Certificate names:
  * ssl.key
  * ssl.crt

* Certificate location:

  * /etc/apache2/ssl/

    ```bash
    $ ls /etc/apache2/ssl/
    ssl.crt   ssl.key
    ```

* How to:
  1. Request a signed certificate for your service/url or Create your own sefl-signed certificates that you want to use

  2. Mount the keys or add them to your Dockerfile

      ```Dockerfile
      COPY etc/apache2/ssl/ssl.key /etc/apache2/ssl/ssl.key
      COPY etc/apache2/ssl/ssl.crt /etc/apache2/ssl/ssl.crt
      ```

### Shibboleth Certificates

* Certificate names:
  * sp-key.pem
  * sp-cert.pem

* Certificate location:

  * /etc/shibboleth/

    ```bash
    $ ls /etc/shibboleth/
    sp-cert.pem   sp-key.pem
    ```

* How to:
  1. Create your own shibboleth certificates


      ```bash
      $ HOSTNAME='example.com'
      $ shib-keygen -f -u _shibd -h ${HOSTNAME} -y 7 -e https://${HOSTNAME}/shibboleth -o etc/shibboleth/
      ```

  2. Mount the keys or add them to your Dockerfile

      ```Dockerfile
      COPY etc/shibboleth/sp-key.pem /etc/shibboleth/sp-key.pem
      COPY etc/shibboleth/sp-cert.pem /etc/shibboleth/sp-cert.pem
      ```

## Examples

## **Using Openshift**

```bash
# Deploy tomcat
$ oc new-app --name tomcat-server

# Deploy shibboleth-sp
$ oc new-app --name shibboleth-sp-for-tomcat \
  --docker-image=jefferyb/shibboleth-sp \
  -e SERVICE_TO_PROTECT='tomcat-server' \
  -e SERVICE_PORT='8080' \
  -e HOSTNAME=tomcat.example.com \
  -e IDP_ENTITY_ID=https://samltest.id/saml/idp \
  -e IDP_METADATA_URL=https://samltest.id/saml/idp \
  -e SUPPORT_EMAIL=root@localhost \
  -e SHIB_METADATA_BACKUP_URL=https://samltest.id/saml/idp \
  -e SHIB_DOWNLOAD_METADATA=true

# Create a route
$ oc create route passthrough shibboleth-sp-for-tomcat --insecure-policy=Redirect --service shibboleth-sp-for-tomcat --port='443-tcp' --hostname=tomcat.example.com
```

You should be redirected to a shibboleth login when you visit https://tomcat.example.com

## **Using docker**

```bash
# Deploy tomcat
docker run -d --name tomcat-server tomcat

# Deploy shibboleth-sp
docker run -d \
  --name shibboleth-sp \
  --link tomcat-server \
  -e SERVICE_TO_PROTECT='tomcat-server' \
  -e SERVICE_PORT='8080' \
  -e HOSTNAME=example.com \
  -e IDP_ENTITY_ID=https://samltest.id/saml/idp \
  -e IDP_METADATA_URL=https://samltest.id/saml/idp \
  -e SUPPORT_EMAIL=root@localhost \
  -e SHIB_METADATA_BACKUP_URL=https://samltest.id/saml/idp \
  -e SHIB_DOWNLOAD_METADATA=true \
  -p 80:80 \
  -p 443:443 \
  jefferyb/shibboleth-sp
```

You should be redirected to a shibboleth login when you visit https://example.com


## **Using a docker image (Dockerfile)**

```Dockerfile
# Dockerfile
FROM jefferyb/shibboleth-sp
MAINTAINER Example User <user@example.com>

ENV HOSTNAME="tomcat.example.com"
####### APACHE SECTION #######
ENV SERVICE_TO_PROTECT="tomcat-server"
ENV SERVICE_PORT="8080"
####### SHIBBOLETH SECTION #######
ENV IDP_ENTITY_ID="https://samltest.id/saml/idp"
ENV IDP_METADATA_URL="https://samltest.id/saml/idp"
ENV SUPPORT_EMAIL='user@example.com'
ENV SHIB_METADATA_BACKUP_URL="https://samltest.id/saml/idp"
ENV SHIB_DOWNLOAD_METADATA=true

COPY etc/apache2/ssl/ /etc/apache2/ssl/
COPY etc/shibboleth/ /etc/shibboleth/
```

```bash
$ tree
.
├── Dockerfile
├── etc
│   ├── apache2
│   │   └── ssl
│   │       ├── ssl.crt
│   │       └── ssl.key
│   └── shibboleth
│       ├── sp-cert.pem
│       └── sp-key.pem

4 directories, 5 files

# Build the Shibboleth image
$ docker build -t shibboleth-sp .

# Deploy tomcat
docker run -d --name tomcat-server tomcat

# Deploy shibboleth-sp
docker run -d \
  --name shibboleth-sp \
  --link tomcat-server \
  -p 80:80 \
  -p 443:443 \
  shibboleth-sp
```

## **Using docker-compose file**

```yaml
# To run it, do:
#   $ docker-compose pull && docker-compose up -d
#
# To upgrade, do:
#   $ docker-compose pull && docker-compose stop && docker-compose rm -f && docker-compose up -d
#
# To check the logs, do:
#   $ docker-compose logs -f
#

version: '2'

services:
  tomcat-server:
    image: tomcat

  shibboleth-sp:
    image: jefferyb/shibboleth
    container_name: shibboleth-sp
    environment:
      ####### APACHE SECTION #######
      - SERVICE_TO_PROTECT='tomcat-server'
      - SERVICE_PORT='8080'
      ####### SHIBBOLETH SECTION #######
      - HOSTNAME='example.com'
      - IDP_ENTITY_ID='https://samltest.id/saml/idp'
      - IDP_METADATA_URL='https://samltest.id/saml/idp'
      - SUPPORT_EMAIL='root@localhost'
      - SHIB_METADATA_BACKUP_URL='https://samltest.id/saml/idp'
      - SHIB_DOWNLOAD_METADATA='true'
    ports:
      - 80:80
      - 443:443
    restart: always
    links:
      - tomcat-server
    # volumes:
    #   - $(pwd)/ssl/ssl.crt:/etc/apache2/ssl/ssl.crt:ro
    #   - $(pwd)/ssl/ssl.key:/etc/apache2/ssl/ssl.key:ro
```

You should be redirected to a shibboleth login when you visit https://example.com
