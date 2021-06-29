# MiniHive package for the Scalable Database Systems lecture

# Copyright 2021, Edson Ramiro Lucas Filho <edson.lucas@uni-passau.de>
# SPDX-License-Identifier: GPL-2.0-only

FROM ubuntu:21.04

MAINTAINER Edson Ramiro Lucas Filho "edson.lucas@uni-passau.de"

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

# change root password
RUN echo 'root:root' | chpasswd

##################################################
# Install Linux required packages
##################################################

ARG DEBIAN_FRONTEND=noninteractive
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
RUN ssh-keygen -t rsa -P '' -f /home/minihive/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 0600 ~/.ssh/authorized_keys

##################################################
# Download and Configure PostgreSQL
##################################################

USER root
WORKDIR /root
RUN sudo gpg \
    --keyserver keys.openpgp.org \
    --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get install -y --no-install-recommends \
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
RUN pg_ctlcluster 13 main start
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
    -c https://ftp.halifax.rwth-aachen.de/apache/hadoop/common/hadoop-3.2.2/hadoop-3.2.2.tar.gz
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
    -c https://ftp.halifax.rwth-aachen.de/apache/spark/spark-3.1.1/spark-3.1.1-bin-hadoop3.2.tgz
RUN tar xzf spark-3.1.1-bin-hadoop3.2.tgz
RUN rm -v spark-3.1.1-bin-hadoop3.2.tgz
WORKDIR spark-3.1.1-bin-hadoop3.2
COPY --chown=minihive:minihive config/spark/* ./conf/
COPY --chown=minihive:minihive config/hive/hive-site.xml ./conf/

##################################################
# Download and Install Python
##################################################

USER minihive
WORKDIR /opt

# Install Python dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN sudo --preserve-env=DEBIAN_FRONTEND \
    apt-get install -y --no-install-recommends \
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
    https://www.python.org/ftp/python/3.9.4/Python-3.9.4.tgz
RUN tar xzf Python-3.9.4.tgz
WORKDIR Python-3.9.4
RUN ./configure --prefix=/usr/local
RUN make -j $(cat /proc/cpuinfo  | grep processor | wc -l)
RUN sudo make altinstall
WORKDIR /opt/
RUN rm Python-3.9.4.tgz
RUN sudo rm -rf Python-3.9.4
RUN sudo update-alternatives --install /usr/bin/python python /usr/local/bin/python3.9  1

##################################################
# Install Python dependencies for MiniHive
##################################################

# Install PIP
RUN wget \
    --no-verbose --show-progress \
    --progress=bar:force:noscrol \
    --no-check-certificate \
    -c https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py --user --no-warn-script-location
RUN /usr/bin/python -m pip install --upgrade pip --no-warn-script-location
RUN rm get-pip.py

RUN /usr/bin/python -m pip install --user --no-cache-dir --no-warn-script-location \
    antlr4-python3-runtime \
    datetime \
    luigi \
    pytest \
    pytest-repeat \
    radb \
    sqlparse \
    unittest2 \
    wheel

# fix antlr version for miniHive
RUN /usr/bin/python -m pip uninstall -y antlr4-python3-runtime
RUN /usr/bin/python -m pip install --user antlr4-python3-runtime==4.7 --no-warn-script-location

##################################################
# Download Docker Content (Data and Examples)
##################################################

WORKDIR /home/minihive/
RUN echo 'echo $GIT_TOKEN' > /home/minihive/.git-askpass
RUN chmod ugo+x /home/minihive/.git-askpass
RUN export GIT_TOKEN=khzrwRPU8Uv52ZzR9Eyj && \
    export GIT_ASKPASS=/home/minihive/.git-askpass && \
    git clone https://git.fim.uni-passau.de/sdbs/minihive/minihive-docker-content.git docker-content
RUN mv docker-content/* . && rm -rf docker-content
RUN ./build.sh
RUN rm build.sh

##################################################
# Launch services when booting Docker
##################################################

USER minihive
WORKDIR /opt
COPY --chown=minihive:minihive bin/entrypoint.sh .
COPY --chown=minihive:minihive bin/restart-services.sh .
RUN chmod 0755 restart-services.sh entrypoint.sh

# Leave bash at $HOME
WORKDIR /home/minihive/
ENTRYPOINT /opt/entrypoint.sh
