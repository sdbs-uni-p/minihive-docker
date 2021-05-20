#!/bin/bash

# Launch sshd
sudo /etc/init.d/ssh start

# Launch PostgreSQL
sudo /etc/init.d/postgresql start

# Launch HDFS
/opt/hadoop-3.2.2/sbin/start-dfs.sh

# Launch MapReduce
/opt/hadoop-3.2.2/sbin/start-yarn.sh

# Launch Spark
/opt/spark-3.1.1-bin-hadoop3.2/sbin/start-all.sh

# Launch Metastore
/opt/apache-hive-3.1.2-bin/bin/hive --service metastore 2>/dev/null &

# We need to hang docker
tail -f /dev/null

