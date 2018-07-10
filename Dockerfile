FROM ubuntu:latest
MAINTAINER Jeffery Bagirimvano <jefferyb@uark.edu>

RUN \
  apt-get update && \
  apt-get install -y ansible

ENV HOSTNAME="localhost"
####### APACHE SECTION #######
ENV APACHE_PORT="8080"
ENV APACHE_HTTP_PORT="8080"
ENV APACHE_HTTPS_PORT="8443"
ENV APACHE_SERVER_ADMIN="webmaster@localhost"
ENV APACHE_DOCUMENTROOT="/var/www/html"
####### TOMCAT SECTION #######
ENV TOMCAT_DOCKER_CONTAINER="kuali-coeus-bundled"
ENV TOMCAT_SESSION_LOCATION="kc-dev"
####### SHIBBOLETH SECTION #######
ENV IDP_ENTITY_ID="https://idp.testshib.org/idp/shibboleth"
ENV IDP_METADATA_URL="http://www.testshib.org/metadata/testshib-providers.xml"
ENV SUPPORT_EMAIL='root@localhost'
ENV SHIB_METADATA_BACKUP_URL="http://www.testshib.org/metadata/testshib-providers.xml"
ENV SHIB_DOWNLOAD_METADATA=true
####### APACHE CERTIFICATE SECTION #######
ENV SSL_CERTS_COUNTRY="US"
ENV SSL_CERTS_LOCALITY="New York"
ENV SSL_CERTS_ORGANIZATION="Your company"
ENV SSL_CERTS_STATE="New York"
# ENV SSL_CERTS_COMMON_NAME=${HOSTNAME} # It will use whatever hostname you set above... Default: localhost
ENV SSL_CERTS_DAYS="365"


ADD playbooks /opt/playbooks

RUN \
  mv /opt/playbooks/hosts /etc/ansible/hosts && \
  ansible-playbook /opt/playbooks/shibboleth-playbook.yaml

RUN \
  chmod -R +r /var/log/apache2 && \
  apt-get clean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

EXPOSE 8080 8443

CMD \
  tail -f /var/log/apache2/access.log \
      -f /var/log/apache2/error.log \
      -f /var/log/apache2/other_vhosts_access.log \
      -f /var/log/shibboleth/shibd.log \
      -f /var/log/shibboleth/shibd_warn.log \
      -f /var/log/shibboleth/signature.log \
      -f /var/log/shibboleth/transaction.log
