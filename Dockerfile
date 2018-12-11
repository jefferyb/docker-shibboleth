FROM ubuntu:latest
MAINTAINER Jeffery Bagirimvano <jefferyb@uark.edu>

ENV HOSTNAME="localhost"
####### APACHE SECTION #######
ENV SERVICE_TO_PROTECT="localhost"
ENV SERVICE_PORT="80"
####### SHIBBOLETH SECTION #######
ENV IDP_ENTITY_ID="https://samltest.id/saml/idp"
ENV IDP_METADATA_URL="https://samltest.id/saml/idp"
ENV SUPPORT_EMAIL='root@localhost'
ENV SHIB_METADATA_BACKUP_URL="https://samltest.id/saml/idp"
ENV SHIB_DOWNLOAD_METADATA=true

RUN \
  apt-get update && \
  apt-get upgrade -y curl ansible gnupg2 apache2

COPY playbooks/hosts /etc/ansible/hosts

RUN \
  ansible localhost -m apt_key -a 'id="294E37D154156E00FB96D7AA26C3C46915B76742" url=http://pkg.switch.ch/switchaai/SWITCHaai-swdistrib.asc state=present' && \
  ansible localhost -m apt_repository -a 'repo="deb http://pkg.switch.ch/switchaai/ubuntu bionic main" state=present' && \
  apt-get update && \
  apt-get install -y --install-recommends shibboleth libapache2-mod-shib2

RUN \
  shibd -t && \
  apache2ctl configtest

RUN a2enmod proxy proxy_http rewrite ssl

ADD playbooks /opt/playbooks

RUN \
  mv /opt/playbooks/hosts /etc/ansible/hosts && \
  ansible-playbook /opt/playbooks/shibboleth-playbook.yaml --diff

RUN \
  apt-get clean && \
  apt-get autoremove -y && \
  service shibd stop && \
  service apache2 stop && \
  rm -fr /var/lib/apt/lists/* /etc/shibboleth/sp-*.pem /etc/apache2/ssl/* /var/run/apache2/apache2.pid 

EXPOSE 80 443

CMD \
  ansible-playbook /opt/playbooks/shibboleth-playbook.yaml --diff && \
  tail -f /var/log/apache2/access.log \
      -f /var/log/apache2/error.log \
      -f /var/log/apache2/other_vhosts_access.log \
      -f /var/log/shibboleth/shibd.log \
      -f /var/log/shibboleth/shibd_warn.log \
      -f /var/log/shibboleth/signature.log \
      -f /var/log/shibboleth/transaction.log
