FROM nginx:1.27.4-perl

# Version de Sympa
ARG version=6.2.76


ENV FCGI_HOST 127.0.0.1
ENV FCGI_PORT 9000
ENV FCGI_SOAP_PORT 10000
ENV ADMINADDR admin@example.com
ENV REMOTES mail.example.com
ENV DEBIAN_FRONTEND noninteractive

VOLUME /etc/sympa/includes
VOLUME /etc/sympa/shared
VOLUME /etc/sympa/sympa.conf

VOLUME /var/lib/sympa
VOLUME /var/log/sympa
VOLUME /var/spool/nullmailer
VOLUME /var/spool/sympa



#
## We additionally install recommended Sympa packages which are libraries.
#
COPY ./patches patches
# Install packages
RUN apt-get update -q && \
    apt-get upgrade -q && \
    apt-get install locales --no-install-recommends --yes && \
    apt-get install openssh-server --yes && \
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    dpkg-reconfigure locales && \
    apt-get install sendmail runit libfcgi-perl libglib2.0-data shared-mime-info libio-socket-ip-perl libio-socket-inet6-perl krb5-locales libmime-types-perl libsasl2-modules libhtml-form-perl libhttp-daemon-perl libxml-sax-expat-perl xml-core libfile-nfslock-perl libsoap-lite-perl libmail-dkim-perl libdatetime-perl libdbi-perl libxml-libxml-perl libxml-perl libmime-encwords-perl libunicode-linebreak-perl libintl-perl libfile-copy-recursive-perl libterm-progressbar-perl libnet-cidr-perl libcgi-pm-perl libtemplate-perl libhtml-stripscripts-parser-perl libarchive-zip-perl libdatetime-format-mail-perl libmime-lite-html-perl libdbd-pg-perl cpanminus spawn-fcgi mhonarc wget --yes
# Install nullmailer and dependancies
RUN apt-get install nullmailer --yes

# Sympa manual installation
RUN echo 'Téléchargement de la version Sympa https://github.com/sympa-community/sympa/releases/download/${version}/sympa-${version}.tar.gz' && \
    wget https://github.com/sympa-community/sympa/releases/download/${version}/sympa-${version}.tar.gz
RUN wget https://github.com/sympa-community/sympa/releases/download/${version}/sympa-${version}.tar.gz.sha256
RUN sha256sum -c sympa-${version}.tar.gz.sha256
RUN apt-get install gcc --yes
RUN groupadd sympa && useradd -g sympa -c 'Sympa user' -b /var/lib -s /bin/sh sympa
RUN tar -xzf sympa-${version}.tar.gz
WORKDIR /sympa-${version}
RUN ./configure --enable-fhs --prefix=/usr/local --with-confdir=/etc/sympa 
RUN apt-get install make --yes
RUN make
RUN make install
RUN echo "LOCAL1" > /etc/sympa/facility
RUN yes |apt-get install rsyslog --yes
RUN sed -i 's/module(load="imklog")/#module(load="imklog")/g' /etc/rsyslog.conf

# Configuration files
COPY ./etc/service /etc/runit/runsvdir/current
COPY ./etc/sympa /etc/sympa
COPY ./etc/nginx /etc/nginx

# Set permissions
RUN chown sympa.sympa -R /etc/sympa

# Cleanup
RUN apt-get remove wget gcc make --yes && apt-get clean all && \
    rm -Rf /sympa-${version}*
# XXX FOR DEBUG PURPOSE
#RUN apt-get install vim --yes

# Create 
RUN mkdir -p /var/lib/sympa/list_data && \ 
    mkdir -p /var/lib/sympa/wwsarchive && \
    mkdir -p /var/spool/sympa/wwsbounce && \ 
    mkdir -p /var/lib/sympa/list_data

# Update sympa conf
WORKDIR /etc/sympa
RUN /bin/bash conf.sh
# runit startup
COPY runservices /usr/sbin/

## logs should go to stdout / stderr
## syslog = kern.log
RUN ln -sfT /dev/stdout /var/log/syslog && \
    ln -sfT /dev/null /var/log/kern.log && \
    ln -sfT /dev/stdout /var/log/sympa.log

ENTRYPOINT ["/usr/sbin/runservices"]
