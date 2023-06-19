# MiniHive package for the Scalable Database Systems lecture

# Copyright 2021, Chair of Scalable Database Systems - University of Passau
# SPDX-License-Identifier: GPL-2.0-only

FROM ubuntu:22.04

ENV MINIHIVE_DOCKER_VERSION=1.0.0

LABEL org.opencontainers.image.authors "Michael Fruth <michael.fruth@uni-passau.de>, Sascha Schiegg <sascha.schiegg@uni-passau.de>"
LABEL org.opencontainers.image.title "miniHive Docker"
LABEL org.opencontainers.image.description "Official miniHive Docker image"
LABEL org.opencontainers.image.url "https://github.com/sdbs-uni-p/minihive-docker"
LABEL org.opencontainers.image.documentation "https://github.com/sdbs-uni-p/minihive-docker"
LABEL org.opencontainers.image.source "https://github.com/sdbs-uni-p/minihive-docker"
LABEL org.opencontainers.image.version ${MINIHIVE_DOCKER_VERSION}
LABEL org.opencontainers.image.vendor "Chair of Scalable Database Systems - University of Passau"
LABEL org.opencontainers.image.licenses "GPL-2.0-only"

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

# change root password
RUN echo 'root:root' | chpasswd

##################################################
# Install Linux required packages
##################################################

RUN apt-get update &&\
    apt-get -y dist-upgrade &&\
    apt-get install -y --no-install-recommends \
        apt-utils \
        bc \
        build-essential \
        curl \
        dos2unix \
        git \
        gnupg2 \
        less \
        lsb-release \
        maven \
        openjdk-8-jdk \
        openjdk-8-jre \
        openssh-client \
        openssh-server \
        scala \
        sudo \
        time \
        unzip \
        vim \
        wget

##################################################
# Remove default software bundled with Docker
##################################################

RUN sudo rm -rf /usr/lib/jvm/java-11-openjdk-amd64/ /usr/lib/jvm/java-1.11.0-openjdk-amd64

##################################################
# Create and Configure minihive user
##################################################

RUN useradd -m -G sudo -s /bin/bash minihive && echo "minihive:minihive" | chpasswd

# Add minihive user to sudo
USER root
WORKDIR /root/
COPY --chown=root:sudo config/etc/sudoers /etc/sudoers
RUN chmod 0440 /etc/sudoers

# Enable users to install apps on /opt
RUN chmod 0777 /opt

# Configure minihive user's environment
USER minihive
WORKDIR /home/minihive
COPY --chown=minihive:minihive config/env/bash_aliases /home/minihive/.bash_aliases
COPY --chown=minihive:minihive config/env/vimrc /home/minihive/.vimrc
COPY --chown=root:root config/etc/motd /etc/motd

# Configure minihive's ssh
USER minihive
WORKDIR /home/minihive

RUN mkdir -p /home/minihive/.ssh
RUN chmod 0700 /home/minihive/.ssh

RUN ssh-keygen -t ed25519 -P '' -f /home/minihive/.ssh/id_ed25519
RUN chmod 0600 ~/.ssh/id_ed25519
RUN chmod 0600 ~/.ssh/id_ed25519.pub

RUN cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
RUN chmod 0600 ~/.ssh/authorized_keys

# Add to known hosts for seamless cloning
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts

# Prepare SSH to cline minihive-docker-content (private repository)
COPY --chown=minihive:minihive config/ssh/* /home/minihive/.ssh/
RUN chmod 0600 ~/.ssh/minihive-docker-content ~/.ssh/minihive-docker-content.pub

##################################################
# Download and Configure PostgreSQL
##################################################

USER root
WORKDIR /root

RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

RUN apt-get update && apt-get install -y --no-install-recommends \
        postgresql-13 \
        postgresql-client-13 \
        postgresql-contrib-13 \
        software-properties-common

WORKDIR /home/postgres
USER postgres
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER minihive WITH SUPERUSER PASSWORD 'minihive';" &&\
    createdb -O minihive minihive
COPY --chown=postgres:postgres config/postgres/* /etc/postgresql/13/main/
RUN chmod 0644 /etc/postgresql/13/main/postgresql.conf
RUN chmod 0640 /etc/postgresql/13/main/pg_hba.conf
RUN /usr/lib/postgresql/13/bin/pg_ctl start -w -t 300 -l "/var/log/postgresql/postgresql-13-main.log" -D "/var/lib/postgresql/13/main" -o "-c config_file=/etc/postgresql/13/main/postgresql.conf"
USER minihive
RUN chmod go+rx /home/minihive # PostgreSQL needs access to minihive's home

##################################################
# Download and Configure Hadoop
##################################################

USER minihive
WORKDIR /opt
RUN wget \
    --no-verbose --show-progress \
    --progress=bar:force:noscrol \
    --no-check-certificate \
    -c https://archive.apache.org/dist/hadoop/common/hadoop-3.2.2/hadoop-3.2.2.tar.gz
RUN tar xzf hadoop-3.2.2.tar.gz
RUN rm -v hadoop-3.2.2.tar.gz
WORKDIR hadoop-3.2.2
COPY --chown=minihive:minihive config/hadoop/* ./etc/hadoop/
ARG JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
RUN ./bin/hdfs namenode -format -force

##################################################
# Download and Configure Hive
##################################################

USER minihive
WORKDIR /opt/
RUN wget \
    --no-verbose --show-progress \
    --progress=bar:force:noscrol \
    --no-check-certificate \
    -c https://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz
RUN tar xzf apache-hive-3.1.2-bin.tar.gz
RUN rm -v apache-hive-3.1.2-bin.tar.gz
WORKDIR apache-hive-3.1.2-bin
COPY --chown=minihive:minihive config/hive/* ./conf/
# fix version of guava
RUN rm lib/guava-19.0.jar
RUN wget \
    --no-verbose --show-progress \
    --progress=bar:force:noscrol \
    --no-check-certificate \
    -c https://repo1.maven.org/maven2/com/google/guava/guava/27.0-jre/guava-27.0-jre.jar -O lib/guava-27.0-jre.jar
# remove conflict with Hadoop slf4j jar
RUN rm lib/log4j-slf4j-impl-2.10.0.jar
RUN sudo /etc/init.d/postgresql start &&\
    psql --command "CREATE USER hive WITH SUPERUSER PASSWORD 'hiverocks';" &&\
    createdb -O hive metastore
ARG PGPASSWORD="hiverocks"
RUN sudo /etc/init.d/postgresql restart &&\
    psql -U hive -d metastore -f scripts/metastore/upgrade/postgres/hive-schema-3.1.0.postgres.sql

##################################################
# Download and Configure Spark
##################################################

USER minihive
WORKDIR /opt/
RUN wget \
    --no-verbose --show-progress \
    --progress=bar:force:noscrol \
    --no-check-certificate \
    -c https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz
RUN tar xzf spark-3.1.2-bin-hadoop3.2.tgz
RUN rm -v spark-3.1.2-bin-hadoop3.2.tgz
WORKDIR spark-3.1.2-bin-hadoop3.2
COPY --chown=minihive:minihive config/spark/* ./conf/
COPY --chown=minihive:minihive config/hive/hive-site.xml ./conf/

##################################################
# Download and Install Python
##################################################

USER minihive
WORKDIR /opt

# Install Python dependencies
RUN sudo apt-get install -y --no-install-recommends \
        curl\
        libbz2-dev \
        libc6-dev \
        libffi-dev \
        libgdbm-dev \
        liblzma-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        llvm \
        tk-dev \
        wget \
        xz-utils \
        zlib1g-dev

RUN wget \
    --no-verbose --show-progress \
    --progress=bar:force:noscrol \
    --no-check-certificate \
    https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
RUN tar xzf Python-3.10.0.tgz
WORKDIR Python-3.10.0
RUN ./configure --enable-optimizations
RUN make -j $(nproc)
RUN sudo make install
WORKDIR /opt/
RUN rm Python-3.10.0.tgz
RUN sudo rm -rf Python-3.10.0

WORKDIR /usr/local/bin/
RUN sudo ln -s python3 python
RUN sudo ln -s pip3 pip

##################################################
# Install Python dependencies for MiniHive
##################################################

WORKDIR /tmp
USER minihive
COPY --chown=minihive:minihive config/python/requirements.txt requirements.txt
# Install all packages as minihive user AND as root (system-level packages are needed for Luigi+Hadoop)
RUN pip install --user --disable-pip-version-check --no-cache-dir -r requirements.txt
RUN sudo pip install --disable-pip-version-check --no-cache-dir -r requirements.txt

##################################################
# Download Docker Content (Data and Examples)
##################################################

WORKDIR /home/minihive/

RUN eval `ssh-agent -s` && ssh-add /home/minihive/.ssh/minihive-docker-content && \
    git clone git@github.com:sdbs-uni-p/minihive-docker-content.git docker-content
RUN mv docker-content/* . && rm -rf docker-content build.sh

##################################################
# Prepare Home Directory
##################################################
USER minihive
WORKDIR /home/minihive/

COPY --chown=minihive:minihive config/home/luigi.cfg .luigi.cfg
COPY --chown=minihive:minihive config/home/radb.ini .radb.ini

##################################################
# Launch services when booting Docker
##################################################

USER minihive
WORKDIR /opt
COPY --chown=minihive:minihive \
    bin/entrypoint.sh \
    bin/restart-services.sh \
    ./
RUN chmod 0755 restart-services.sh entrypoint.sh

# Leave bash at $HOME
WORKDIR /home/minihive/
ENTRYPOINT /opt/entrypoint.sh
