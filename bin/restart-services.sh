#!/bin/bash

# kill all java clients
function kill_all_clients () {
    for pid in $(ps xa | grep java | grep -i "$1" | grep -v "grep" | awk -F' ' '{print $1}' | tr '\n' ' '); do
        kill -9 $pid
    done
}

# run cmd and print status
function run_cmd () {
    echo -ne " *** $1 ... "
    ${@:2} 2>&1 > /dev/null && { echo ok; } || { echo fail; }
}

function run_cmd_bg () {
    echo " *** $1 is running in background."
    ${@:2} 2>&1 > /dev/null &
}

# Restart PostgreSQL
run_cmd "Restart PostgreSQL" "sudo /etc/init.d/postgresql restart"

# Restart HDFS
run_cmd "Stop HDFS" "/opt/hadoop-3.2.2/sbin/stop-dfs.sh"
run_cmd "Start HDFS" "/opt/hadoop-3.2.2/sbin/start-dfs.sh"

# Restart MapReduce
run_cmd "Stop YARN" "/opt/hadoop-3.2.2/sbin/stop-yarn.sh"
run_cmd "Start YARN" "/opt/hadoop-3.2.2/sbin/start-yarn.sh"

# Restart Spark
run_cmd "Stop Spark" "/opt/spark-3.1.1-bin-hadoop3.2/sbin/stop-all.sh"
run_cmd "Start Spark" "/opt/spark-3.1.1-bin-hadoop3.2/sbin/start-all.sh"

# Restart Metastore
kill_all_clients "metastore"
run_cmd_bg "Metastore" "/opt/apache-hive-3.1.2-bin/bin/hive --service metastore"
