[![](https://images.microbadger.com/badges/version/jefferyb/shibboleth-sp.svg)](http://microbadger.com/images/jefferyb/shibboleth-sp "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/jefferyb/shibboleth-sp.svg)](http://microbadger.com/images/jefferyb/shibboleth-sp "Get your own image badge on microbadger.com")

## jefferyb/shibboleth-sp
This docker container should work with any tomcat web server/servlet...

## Supported tags
-	[`latest` (*Dockerfile*)](https://github.com/jefferyb/docker-shibboleth-sp/blob/master/Dockerfile)

## Features
- HTTPS support.
- Protect a path.
- Automatically configure with your own settings.

## Environment variables
- **HOSTNAME** : *(default: "localhost")*

###### APACHE SECTION ######
- **APACHE_PORT** : *(default: "80")*
- **APACHE_SERVER_ADMIN** : *(default: "webmaster@localhost")*
- **APACHE_DOCUMENTROOT** : *(default: "/var/www/html")*

###### TOMCAT SECTION ######
- **TOMCAT_DOCKER_CONTAINER** : *(default: "kuali-coeus-bundled")* Should be the name of your tomcat container or the hostname of where you tomcat lives... This setting is for ProxyPass & ProxyPassReverse
- **TOMCAT_SESSION_LOCATION** : *(default: "kc-dev")* It should be the place you want to protect. For example: to protect "kc-dev" at https://example.com/kc-dev, just set it as "TOMCAT_SESSION_LOCATION=kc-dev". To protect the root, `/`, just leave it empty.

###### SHIBBOLETH SECTION ######
- **IDP_ENTITY_ID** : *(default: "https://idp.testshib.org/idp/shibboleth")*
- **IDP_METADATA_URL** : *(default: "http://www.testshib.org/metadata/testshib-providers.xml")*
- **SUPPORT_EMAIL** : *(default: 'root@localhost')*
- **SHIB_METADATA_BACKUP_URL** : *(default: "http://www.testshib.org/metadata/testshib-providers.xml")*
- **SHIB_DOWNLOAD_METADATA** : *(default: true)*

###### APACHE CERTIFICATE SECTION ######
This section is useful during build time, for creating self-signed certificates...

- **SSL_CERTS_COUNTRY** : *(default: "US")*
- **SSL_CERTS_LOCALITY** : *(default: "New York")*
- **SSL_CERTS_ORGANIZATION** : *(default: "Your company")*
- **SSL_CERTS_STATE** : *(default: "New York")*
- **SSL_CERTS_COMMON_NAME** : This will use whatever hostname you set above... Default: localhost
- **SSL_CERTS_DAYS** : *(default: "365")*

## Port
- **80**.
- **443**.

## Setup
We'll have 2 examples:
In this example, we will setup [Kuali Coeus](https://hub.docker.com/r/jefferyb/kuali_coeus) with HTTPS enabled (using letsencrypt), that you can access at https://example.com/kc-dev.

```console
docker run -d \
  --name kuali-coeus-bundled \
  -h kualicoeusbundled \
  -e KUALI_APP_URL=example.com \
  -e KUALI_APP_URL_PORT= \
  -e TZ=America/Chicago \
  jefferyb/kuali_coeus

docker run -d \
  --name shibboleth-sp-server \
  --link kuali-coeus-bundled \
  -e HOSTNAME=example.com \
  -e TOMCAT_DOCKER_CONTAINER=kuali-coeus-bundled \
  -e TOMCAT_SESSION_LOCATION=kc-dev \
  -e IDP_ENTITY_ID=https://idp.testshib.org/idp/shibboleth \
  -e IDP_METADATA_URL=http://www.testshib.org/metadata/testshib-providers.xml \
  -e SUPPORT_EMAIL=root@localhost \
  -e SHIB_METADATA_BACKUP_URL=http://www.testshib.org/metadata/testshib-providers.xml \
  -e SHIB_DOWNLOAD_METADATA=true \
  -v /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/example.com/cert.pem:/etc/ssl/certs/ssl-cert-snakeoil.pem:ro \
  -v /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/example.com/privkey.pem:/etc/ssl/private/ssl-cert-snakeoil.key:ro \
  -p 80:80 \
  -p 443:443 \
  jefferyb/shibboleth-sp

```

And now you can access Kuali Coeus at https://example.com/kc-dev

In next example, we will setup a tomcat instance with HTTPS enabled, that you can access at https://example.com.

```console
docker run -d \
  --name tomcat-server \
  tomcat:8.0

docker run -d \
  --name shibboleth-sp-server \
  --link tomcat-server \
  -e HOSTNAME=example.com \
  -e TOMCAT_DOCKER_CONTAINER=tomcat-server \
  -e TOMCAT_SESSION_LOCATION= \
  -e IDP_ENTITY_ID=https://idp.testshib.org/idp/shibboleth \
  -e IDP_METADATA_URL=http://www.testshib.org/metadata/testshib-providers.xml \
  -e SUPPORT_EMAIL=root@localhost \
  -e SHIB_METADATA_BACKUP_URL=http://www.testshib.org/metadata/testshib-providers.xml \
  -e SHIB_DOWNLOAD_METADATA=true \
  -p 80:80 \
  -p 443:443 \
  jefferyb/shibboleth-sp

```

You should be redirected to a shibboleth login when you visit https://example.com...

**Using docker-compose file**

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
      kuali-coeus:
        ####### Environment vars for kc-config.xml
        environment:
          - "KUALI_APP_URL=example.com"
          - "KUALI_APP_URL_PORT="
          - "TZ=America/Chicago"
        image:          jefferyb/kuali_coeus
        container_name: kuali-coeus-bundled
        hostname:       kualicoeusbundled
        restart:        always

      shibboleth:
        links:
          - kuali-coeus
        environment:
          - "HOSTNAME=example.com"
          - "TOMCAT_DOCKER_CONTAINER=kuali-coeus-bundled"
          - "TOMCAT_SESSION_LOCATION=kc-dev"
          - "TZ=America/Chicago"
        ports:
          - 80:80
          - 443:443
        image: jefferyb/shibboleth
        container_name: shibboleth-server
        hostname: shibbolethserver
        restart: always
        volumes:
          ####### SHIBBOLETH SECTION #######
          - "IDP_ENTITY_ID=https://idp.testshib.org/idp/shibboleth"
          - "IDP_METADATA_URL=http://www.testshib.org/metadata/testshib-providers.xml"
          - "SUPPORT_EMAIL=root@localhost"
          - "SHIB_METADATA_BACKUP_URL=http://www.testshib.org/metadata/testshib-providers.xml"
          - "SHIB_DOWNLOAD_METADATA=true"
          ####### CERTS CERTIFICATES #######
          - /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/example.com/cert.pem:/etc/ssl/certs/ssl-cert-snakeoil.pem:ro
          - /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/example.com/privkey.pem:/etc/ssl/private/ssl-cert-snakeoil.key:ro
