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

RUN apt-get update && apt-get -y dist-upgrade
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y --no-install-recommends \
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
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
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

##################################################
# Download and Configure Hadoop
##################################################

USER minihive
WORKDIR /opt
RUN wget -c https://ftp.halifax.rwth-aachen.de/apache/hadoop/common/hadoop-3.2.2/hadoop-3.2.2.tar.gz
RUN tar xvzf hadoop-3.2.2.tar.gz
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
RUN wget -c https://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz
RUN tar xvzf apache-hive-3.1.2-bin.tar.gz
RUN rm -v apache-hive-3.1.2-bin.tar.gz
WORKDIR apache-hive-3.1.2-bin
COPY --chown=minihive:minihive config/hive/* ./conf/
# fix version of guava
RUN rm lib/guava-19.0.jar
RUN wget -c https://repo1.maven.org/maven2/com/google/guava/guava/27.0-jre/guava-27.0-jre.jar -O lib/guava-27.0-jre.jar
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
RUN wget -c https://ftp.halifax.rwth-aachen.de/apache/spark/spark-3.1.1/spark-3.1.1-bin-hadoop3.2.tgz
RUN tar xvzf spark-3.1.1-bin-hadoop3.2.tgz
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

RUN wget https://www.python.org/ftp/python/3.9.4/Python-3.9.4.tgz
RUN tar xvzf Python-3.9.4.tgz
WORKDIR Python-3.9.4
RUN ./configure --prefix=/usr/local
RUN make -j $(cat /proc/cpuinfo  | grep processor | wc -l)
RUN sudo make altinstall
WORKDIR /opt/
RUN rm Python-3.9.4.tgz
RUN sudo rm -rf Python-3.9.4
RUN sudo update-alternatives --install /usr/bin/python python /usr/local/bin/python3.9  1

# Install PIP
WORKDIR /opt/
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN sudo /usr/local/bin/python3.9 get-pip.py
RUN rm get-pip.py

##################################################
# Install Python dependencies for MiniHive
##################################################

RUN sudo pip3 install --upgrade pip
RUN sudo pip3 install --no-cache-dir \
    antlr4-python3-runtime \
    datetime \
    luigi \
    pytest \
    pytest-repeat \
    radb \
    sqlparse \
    unittest2 \
    wheel

RUN sudo pip uninstall -y antlr4-python3-runtime
RUN sudo pip install antlr4-python3-runtime==4.7

##################################################
# Download Docker Content (Data and Examples)
##################################################

WORKDIR /home/minihive/
RUN echo 'echo $GIT_TOKEN' > /home/minihive/.git-askpass
RUN chmod ugo+x /home/minihive/.git-askpass
RUN export GIT_TOKEN=khzrwRPU8Uv52ZzR9Eyj && \
    export GIT_ASKPASS=/home/minihive/.git-askpass && \
    git clone https://git.fim.uni-passau.de/sdbs/minihive/minihive-docker-content.git
RUN mv minihive-docker-content/* .
RUN rm -rf minihive-docker-content
RUN ./get-extra.sh
RUN rm get-extra.sh

# Configure Luigi
COPY --chown=minihive:minihive config/minihive/luigi.cfg ./minihive/milestone3/

##################################################
# Launch services when booting Docker
##################################################

USER minihive
WORKDIR /opt
COPY --chown=minihive:minihive bin/launch-services.sh .
COPY --chown=minihive:minihive bin/restart-services.sh .
RUN chmod 0755 restart-services.sh launch-services.sh

# Leave bash at $HOME
WORKDIR /home/minihive/
ENTRYPOINT /opt/launch-services.sh
