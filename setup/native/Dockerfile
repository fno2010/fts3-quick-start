FROM centos:7

# Visual Studio Code Dev Container Environment
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# FTS Related Repos
ARG ftsrepo=https://fts-repo.web.cern.ch/fts-repo/fts3-prod-el7.repo
ARG ftsdeprepo=https://fts-repo.web.cern.ch/fts-repo/fts3-depend-el7.repo
ARG dmcrepo=https://dmc-repo.web.cern.ch/dmc-repo/dmc-devel-el7.repo

# Add Repos
ADD $ftsrepo /etc/yum.repos.d/fts3-prod-el7.repo
ADD $ftsdeprepo /etc/yum.repos.d/fts3-depend-el7.repo
ADD $dmcrepo /etc/yum.repos.d/dmc.repo
ADD packaging/rpm/fts.spec /

# Set Up Visual Studio Code User
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && ulimit -n 102400

# Install Development Dependencies
RUN yum install -y epel-release \
    && yum upgrade -y \
    && yum --enablerepo=*-testing clean all \
    && yum groupinstall -y 'Development Tools' \
    && yum install -y centos-release-scl \
                      yum-plugin-priorities yum-utils createrepo git \
                      mysql multitial gfal2-all gfal2-plugin* \
                      jsoncpp-devel \
    && yum install -y devtoolset-8 \
    && scl enable devtoolset-8 -- bash \
    && yum-builddep -y "/fts.spec" \
    && echo 'source /opt/rh/devtoolset-8/enable' >> /etc/profile.d/devtoolset.sh \

# Install FTS and Runtime Dependencies
    && yum install -y fts-server fts-rest-client fts-rest-server fts-monitoring fts-mysql fts-msg \
    && yum clean all

# Override repo priorities
RUN echo "priority=2" >> /etc/yum.repos.d/dmc.repo \
    && echo "priority=10" >> /etc/yum.repos.d/fts3-prod-el7.repo \
    && echo "priority=20" >> /etc/yum.repos.d/fts3-depend-el7.repo
COPY native/fts3-local.repo.template /fts3-local.repo.template

# Database configuration
COPY native/fts3config /etc/fts3/fts3config
RUN chmod +x /usr/share/fts/fts-database-upgrade.py

# Configuration for FTSREST and FTSMON
COPY native/fts3rest.conf /etc/httpd/conf.d/fts3rest.conf
COPY native/fts3restconfig /etc/fts3/fts3restconfig
RUN echo "" > /etc/httpd/conf.d/ssl.conf &&\
    echo "" > /etc/httpd/conf.d/autoindex.conf &&\
    echo "" > /etc/httpd/conf.d/userdir.conf &&\
    echo "" > /etc/httpd/conf.d/welcome.conf &&\
    echo "" > /etc/httpd/conf.d/zgridsite.conf

# FTS monitoring ActiveMQ configuration
COPY native/fts-msg-monitoring.conf /etc/fts3/fts-msg-monitoring.conf

# Entrypoint waiting script for MySQL
COPY native/wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

# Shortcut for logfiles
COPY native/logshow /usr/local/bin/logshow
RUN chmod +x /usr/local/bin/logshow \
    && touch /var/log/fts3/fts3server.log \
    && chown -R fts3:fts3 /var/log/fts3/fts3server.log \
    && touch /var/log/fts3rest/fts3rest.log \
    && chown -R fts3:fts3 /var/log/fts3rest

EXPOSE 8446 8449
ADD native/docker-entrypoint.sh /
