# miniHive's Container

1. [miniHive's Docker](#minihive-docker)\
1.1 [Building the Docker image](#building-image)\
1.2 [Running the Docker container](#running-container)\
1.3 [Accessing the Docker container](#accessing-container)\
1.4 [Stop and Start the Docker container](#stop-and-start)\
1.5 [Copy files to/from your local machine](#copy-from-to)\
1.6 [How to install extra software](#install-extra)
2. [Running applications](#running-apps)

These files are part of a Scalable Database Systems course taught at the University of Passau. These files are used to build and configure a container image with the systems required during the course, including [Hadoop](https://hadoop.apache.org/docs/r3.2.2/) (v. 3.2.2), [Hive](https://cwiki.apache.org/confluence/display/hive/languagemanual) (v. 3.1.2), and [Spark](https://spark.apache.org/docs/latest/) (v. 3.1.2).

In this course students build their own SQL-on-Hadoop engine as a term project, called [miniHive](https://github.com/miniHive/assignment). This term project is written in Python and compiles SQL queries into MapReduce workflows. The image provides [Python 3.10](https://docs.python.org/3/reference/index.html) and the libraries [RADB](https://users.cs.duke.edu/~junyang/radb/), [Luigi](https://luigi.readthedocs.io/en/stable/), [SQLparse](https://sqlparse.readthedocs.io/en/latest/) for students to build miniHive.

Note that the miniHive container does not contain a Graphical User Interface.

# miniHive's Docker <a name="minihive-docker"></a>

The following steps will assist you to build, run and access the miniHive's Docker image. Please, check the [official Docker documentation](https://docs.docker.com/engine/reference/commandline/docker/) for additional information in case you have questions regarding specific steps, error messages or the terminology used.

### Building the Docker image <a name="building-image"></a>
You can either use the pre-built Docker image or build the image on your own.

Based on the instructions below, the docker image is named 'minihive-docker'.

#### Pre-Built Image
Get the pre-built docker image:

```shell
docker pull ghcr.io/sdbs-uni-p/minihive-docker:latest
```

#### Building on your own
You can download and build the Docker image with the commands below.
This step may take a while because all required software will be downloaded, installed and configured during the build (about 5-10 minutes depending on your machine and internet connection).

After the execution of the *docker build* command you should have a message saying the build was successful.

```console
foo@bar:~$ git clone https://github.com/sdbs-uni-p/minihive-docker.git
foo@bar:~$ cd minihive-docker
foo@bar:~/minihive-docker$ docker build --no-cache -t minihive-docker .
[...]
Step 107/107 : ENTRYPOINT /opt/entrypoint.sh
[...]
Successfully built 1517444f3ff1
Successfully tagged minihive-docker:latest
```

### Running the Docker container <a name="running-container"></a>

Now, you need to create a container. The following command will create and run a *container* and name it *minihive*. This command will also redirect the connections on your local port 2222 to the container's port 22.

```console
foo@bar:~/minihive-docker$ docker run -d --name minihive -p 2222:22 minihive-docker
```

At this point you have the docker container running in the background. You can verify that the container is running with the following command:

```console
foo@bar:~/minihive-docker$ docker ps -a
CONTAINER ID   IMAGE             COMMAND                  CREATED        STATUS        PORTS                  NAMES
291614e93438   minihive-docker   "/bin/sh -c /opt/lau…"   18 hours ago   Up 18 hours   0.0.0.0:2222->22/tcp   minihive
```

### Accessing the Docker container <a name="accessing-container"></a>

Using the following command you can access the *minihive* container via ssh on localhost, port 2222. Please, check the ssh's [manual pages](https://www.openssh.com/manual.html) for more information. The user name and password are:

- **username**: minihive
- **password**: minihive

The minihive user has sudo rights.

You should see a message like this when accessing the container.

```console
foo@bar:~/minihive-docker$ ssh -p 2222 minihive@localhost
minihive@localhost's password:
Welcome to Ubuntu 21.04 (GNU/Linux 5.10.0-6-amd64 x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
           _       _ _   _ _
 _ __ ___ (_)_ __ (_) | | (_)_   _____
| '_ ` _ \| | '_ \| | |_| | \ \ / / _ \
| | | | | | | | | | |  _  | |\ V /  __/
|_| |_| |_|_|_| |_|_|_| |_|_| \_/ \___|

miniHive Docker

minihive@291614e93438:~$
```


Note that the SSH server, as well as the other services of Hadoop, HDFS, Hive, and Spark may take a few seconds to start (about 10-30 seconds depending of your machine). So, wait a few seconds after you log in for the first time. If all services are running, then the command below should return **9**.

```console
minihive@291614e93438:~$ ps xa | grep java | wc -l
9
```

If the command above report a number different than 9, then, you can restart all services by calling this script:

```console
minihive@291614e93438:~$ /opt/restart-services.sh
```

### 

SSH will not let you access a host:port combination that has a different identification then the one previously stored. This is to avoid man-in-the-middle attacks.
In case you receive a similar warning from SSH after you recreated the container, you can solve this by removing the old identification that is stored in the *~/.ssh/known_hosts* file.

```console
foo@bar:~$ ssh -p 2222 minihive@localhost
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ECDSA key sent by the remote host is
SHA256:k9HcUYIJpme1h9JJIFnjhniFLRWudOJJ57pUH1aV/BQ.
Please contact your system administrator.
Add correct host key in /home/foo/.ssh/known_hosts to get rid of this
message.
Offending ECDSA key in /home/foo/.ssh/known_hosts:10
   remove with:
   ssh-keygen -f "/home/foo/.ssh/known_hosts" -R "[localhost]:2222"
ECDSA host key for [localhost]:2222 has changed and you have requested
strict checking.
Host key verification failed.
```

To remove the old identification you need to execute the command presented by SSH, and SSH will take care of removing it.

```console
   ssh-keygen -f "/home/foo/.ssh/known_hosts" -R "[localhost]:2222"
```

### Stop and Start the Docker container <a name="stop-and-start"></a>

Now, lets create a new empty file and exit the container.

```console
minihive@291614e93438:~$ touch my-file.txt
minihive@291614e93438:~$ ls
README.md  data  hadoop  hive  my-file.txt  radb  spark  tpch
minihive@291614e93438:~$ exit
```

You can stop the container and start it again. Your file ``my-file.txt'' should be there.

```console
foo@bar:~/minihive-docker$ docker stop minihive
foo@bar:~/minihive-docker$ docker ps -a
CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS                       PORTS     NAMES
291614e93438   minihive-docker   "/bin/sh -c /opt/ent…"   4 minutes ago   Exited (137) 2 seconds ago             minihive
foo@bar:~/minihive-docker$ docker start minihive
foo@bar:~/minihive-docker$ ssh -p 2222 minihive@localhost
minihive@localhost's password:
minihive@291614e93438:~$ ls
README.md  hadoop  hive  my-file.txt  radb  spark  tpch
```

### Copy files to/from your local machine<a name="copy-from-to"></a>

You can copy files to/from your local machine using scp.

Example:

- Copy to:
```console
foo@bar:~/minihive-docker$ mkdir -p foo/bar
foo@bar:~/minihive-docker$ touch foo/a.txt
foo@bar:~/minihive-docker$ scp -P2222 -r foo minihive@localhost:
minihive@localhost's password:
a.txt                       100%    0     0.0KB/s   00:00
foo@bar:~/minihive-docker$ ssh -p 2222 minihive@localhost
minihive@localhost's password:
minihive@291614e93438:~$ ls foo/
a.txt  bar
```

- Copy from:
```console
foo@bar:~/minihive-docker$ scp -P2222 -r  minihive@localhost:/home/minihive/data/ data
minihive@localhost's password:
countries.csv               100% 4120     8.9MB/s   00:00
currency-code.csv           100%   17KB  26.3MB/s   00:00
airport-code.csv            100% 6086KB 183.3MB/s   00:00
region-population.csv       100%  477KB 183.8MB/s   00:00
population-city.csv         100% 3343KB 212.3MB/s   00:00
region-gdp.csv              100%  444KB 225.2MB/s   00:00
population-by-country.csv   100%  126KB 183.5MB/s   00:00
country-codes.csv           100%  127KB 177.0MB/s   00:00
cities.csv                  100%  875KB 232.7MB/s   00:00
population-rural.csv        100%  462KB 206.3MB/s   00:00
airport-flow.tsv            100%   14MB 216.9MB/s   00:00
foo@bar:~/minihive-docker$ ls -l data/
total 26776
-rw-r--r-- 1 user user  6232459 May 21 11:00 airport-code.csv
-rw-r--r-- 1 user user 15147984 May 21 11:00 airport-flow.tsv
-rw-r--r-- 1 user user   895586 May 21 11:00 cities.csv
-rw-r--r-- 1 user user     4120 May 21 11:00 countries.csv
-rw-r--r-- 1 user user   129984 May 21 11:00 country-codes.csv
-rw-r--r-- 1 user user    17866 May 21 11:00 currency-code.csv
-rw-r--r-- 1 user user   129071 May 21 11:00 population-by-country.csv
-rw-r--r-- 1 user user  3423631 May 21 11:00 population-city.csv
-rw-r--r-- 1 user user   473447 May 21 11:00 population-rural.csv
-rw-r--r-- 1 user user   454342 May 21 11:00 region-gdp.csv
-rw-r--r-- 1 user user   487991 May 21 11:00 region-population.csv
```

### How to install extra software <a name="install-extra"></a>

You can install extra software with apt-get. This command installs emacs.

```console
minihive@291614e93438:~$ sudo apt-get install emacs
```

# Running applications <a name="running-apps"></a>

This is the content of the miniHive Docker.
The directories *hadoop*, *hive*, *spark*, and *radb* contain sample data and example applications to be run in each system.
The *tpch* directory contains the [TPC-H](http://www.tpc.org/tpch/) benchmark that can be run on Hive.
Please, read the file *README.md* (in the HOME directory) for instructions on how to run example applications on Hadoop, Hive, Spark and RADB.

```console
minihive@291614e93438:~$ ls -lh
total 32K
drwxr-xr-x 2 minihive minihive 4.0K May 18 16:08 spark
drwxr-xr-x 2 minihive minihive 4.0K May 18 16:08 hive
-rw-r--r-- 1 minihive minihive 1.4K May 18 16:08 README.md
drwxr-xr-x 1 minihive minihive 4.0K May 18 16:08 radb
drwxr-xr-x 7 minihive minihive 4.0K May 18 16:08 tpch
drwxr-xr-x 2 minihive minihive 4.0K May 18 16:08 hadoop
minihive@291614e93438:~$ less README.md
```

You can use the following commands to run examples on each system:

##### RADB

You can execute an example on RADB using the command below:

```console
minihive@291614e93438:~$ cd radb
minihive@291614e93438:~$ radb -i beers.ra beers.db
minihive@291614e93438:~$ radb beers.db
ra> \list;
database relations:
  Bar(name:string, address:string)
  Beer(name:string, brewer:string)
  Drinker(name:string, address:string)
  Frequents(drinker:string, bar:string, times_a_week:number)
  Likes(drinker:string, beer:string)
  Serves(bar:string, beer:string, price:number)
ra> \select_{name like 'B%'} Beer;
(name:string, brewer:string)
----------------------------------------------------------------------
Budweiser, Anheuser-Busch Inc.
----------------------------------------------------------------------
1 tuple returned
ra> \quit;
```

The "pizza scenario" database is also available and can be loaded as described above.

##### Hadoop

One example is the wordcount problem. Use the commands below to compile and run the wordcount example. Please, make sure that more than 10% of the total disk on your machine is free.

```console
minihive@291614e93438:~$ cd hadoop
minihive@291614e93438:~/hadoop$ ls
de  data
minihive@291614e93438:~/hadoop$ javac -classpath $(hadoop classpath) de/uni_passau/minihive/WordCount.java
minihive@291614e93438:~/hadoop$ jar cf wordcount.jar -C . de
minihive@291614e93438:~/hadoop$ ls -l de/uni_passau/minihive
-rw-rw-r-- 1 user user 1793 May 21 11:00 'WordCount$IntSumReducer.class'
-rw-rw-r-- 1 user user 1790 May 21 11:00 'WordCount$TokenizerMapper.class'
-rw-rw-r-- 1 user user 1988 May 21 11:00  WordCount.class
-rw-rw-r-- 1 user user 3305 May 21 11:00  WordCount.java
minihive@291614e93438:~/hadoop$ ls -l
drwxrwxr-x 2 user user 4096 May 21 11:00  data
drwxrwxr-x 2 user user 4096 May 21 11:00  de
-rw-rw-r-- 1 user user 3325 May 21 11:00  wordcount.jar
minihive@291614e93432:~/hadoop$ hdfs dfs -mkdir /user
minihive@291614e93432:~/hadoop$ hdfs dfs -mkdir /user/minihive
minihive@291614e93438:~/hadoop$ hdfs dfs -put data/cities.csv
minihive@291614e93438:~/hadoop$ hdfs dfs -ls
found 1 items
-rw-r--r--   1 minihive supergroup     235514 2021-05-20 11:42 cities.csv
minihive@291614e93438:~/hadoop$
minihive@291614e93438:~/hadoop$ hadoop jar wordcount.jar de.uni_passau.minihive.WordCount cities.csv count
[...]
minihive@291614e93438:~/hadoop$ hdfs dfs -ls count/
Found 2 items
-rw-r--r--   1 minihive supergroup          0 2021-05-20 11:58 count/_SUCCESS
-rw-r--r--   1 minihive supergroup     237835 2021-05-20 11:58 count/part-r-00000
minihive@291614e93438:~/hadoop$ hdfs dfs -cat count/part*
[...]
‘Izbat  1
‘Izrā,Jordan,Karak,248923 1
‘Ulá,Saudi      1
‘Īsá,Bahrain,Southern  1
‘Īsá,Egypt,Al   1
’Aïn    9
```

##### Hive

You can execute an example on Hive using the command below:

```console
minihive@291614e93438:~$ cd hive
minihive@291614e93438:~/hive$ hive -f students.ddl
minihive@291614e93438:~/hive$ hive -f students.sql
[...]
Starting Job = job_1621589494056_0002, Tracking URL = http://80497d38c884:8088/proxy/application_1621589494056_0002/
Kill Command = /opt/hadoop-3.2.2/bin/mapred job  -kill job_1621589494056_0002
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 1
2021-05-21 11:00:11,086 Stage-1 map = 0%,  reduce = 0%
2021-05-21 11:00:11,413 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 4.35 sec
2021-05-21 11:00:11,694 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 7.69 sec
MapReduce Total cumulative CPU time: 7 seconds 690 msec
Ended Job = job_1621589494056_0002
MapReduce Jobs Launched:
Stage-Stage-1: Map: 1  Reduce: 1   Cumulative CPU: 7.69 sec   HDFS Read: 13084 HDFS Write: 145 SUCCESS
Total MapReduce CPU Time Spent: 7 seconds 690 msec
OK
33      C3T
99      C2T
123     C1T
Time taken: 27.418 seconds, Fetched: 3 row(s)
```

##### Spark

The example below calculates the number *Pi* on Spark:

```console
minihive@291614e93438:~$ cd spark
minihive@291614e93438:~/spark$ spark-submit \
            --class org.apache.spark.examples.SparkPi \
            --master local[2] /opt/spark-3.1.2-bin-hadoop3.2/examples/jars/spark-examples_2.12-3.1.2.jar 100
```

##### Luigi

Luigi supports three different modes of execution:

- Local
    - Data is loaded from local disk and results are also stored there.
- HDFS
    - Data is loaded from HDFS and results are also stored there.
- Mock
    - Data is mocked, i.e. hard-coded dummy data is embedded in the script and used. This mode is used specifically for unit tests.

In the following, the three different variants for luigi are shown, using the example of the wordcount problem:

```console
minihive@3f0555a99348:~$ cd python-luigi/
minihive@3f0555a99348:~/python-luigi$ ./run-local # Local
minihive@3f0555a99348:~/python-luigi$ ./run-hdfs # HDFS
minihive@3f0555a99348:~/python-luigi$ ./run-test # Mock
```

