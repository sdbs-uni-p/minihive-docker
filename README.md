# miniHive's Docker <a name="minihive-docker"></a>

1. [miniHive's Docker](#minihive-docker)\
1.1 [Building the Docker image](#building-image)\
1.2 [Running the Docker container](#running-container)\
1.3 [Accessing the Docker container](#accessing-container)\
1.4 [Stop and Start the Docker container](#stop-and-start)\
1.5 [Copy files to/from your local machine](#copy-from-to)\
1.6 [How to install extra software](#install-extra)
2. [Running applications](#running-apps)


These files are part of a database systems course taught at the University of Passau. These files are used to build and configure a docker image with the systems required during the course, including [Hadoop](https://hadoop.apache.org/docs/r3.2.2/) (v. 3.2.2), [Hive](https://cwiki.apache.org/confluence/display/hive/languagemanual) (v. 3.1.2), and [Spark](https://spark.apache.org/docs/latest/) (v. 3.1.1).

In this course students also build their own SQL-on-Hadoop engine as a term project, called [miniHive](https://github.com/miniHive/assignment). This term project is written in Python and compiles SQL queries into MapReduce workflows. The Docker image provides [Python 3.9](https://docs.python.org/3/reference/index.html) and the libraries [RADB](https://users.cs.duke.edu/~junyang/radb/), [Luigi](https://luigi.readthedocs.io/en/stable/), [SQLparse](https://sqlparse.readthedocs.io/en/latest/) for students to build miniHive.

Note that the miniHive docker does not contain a Graphical User Interface.

The following steps will assist you to build, run and access the miniHive's Docker image. Please, check the [official Docker documentation](https://docs.docker.com/engine/reference/commandline/docker/) for additional information in case you have questions regarding specific steps, error messages or the terminology used.

### Building the Docker image <a name="building-image"></a>

You can download and build the Docker image with the commands below.
The docker image is named 'minihive-docker'.
This step may take a while because all required software will be downloaded, installed and configured during the build (about 5-10 minutes depending on your machine and internet connection).

After the execution of the *docker build* command you should have a message saying the build was successful.

```console
foo@bar:~$ git clone https://git.fim.uni-passau.de/sdbs/minihive/minihive-docker.git
foo@bar:~$ docker build -t minihive-docker .
[...]
Step 105/106 : WORKDIR /home/minihive/
 ---> Using cache
 ---> ad484932367b
Step 106/106 : ENTRYPOINT /opt/launch-services.sh
 ---> Using cache
 ---> 5e914023974a
Successfully built 5e914023974a
Successfully tagged minihive-docker:latest
```

### Running the Docker container <a name="running-container"></a>

Now, you need to create a container. The following command will create and run a *container* and name it *minihive*. This command will also redirect the connections on your local port 2222 to the container's port 22.

```console
foo@bar:~$ docker run -t -d --name minihive -p 2222:22 minihive-docker
```

At this point you have the docker container running in the background. You can verify that the container is running with the following command:

```console
foo@bar:~$ docker ps -a
CONTAINER ID   IMAGE             COMMAND                  CREATED        STATUS        PORTS                  NAMES
291614e93438   minihive-docker   "/bin/sh -c /opt/lau…"   18 hours ago   Up 18 hours   0.0.0.0:2222->22/tcp   minihive
```

### Accessing the Docker container <a name="accessing-container"></a>

Using the following command you can access the *minihive* container via ssh on localhost, port 2222. The user name and password are:

- **username**: minihive
- **password**: minihive

The minihive user has sudo rights.

You should see a message like this when accessing the container.

```console
foo@bar:~$ ssh -p 2222 minihive@localhost
minihive@localhost's password:
Welcome to Ubuntu 21.04 (GNU/Linux 5.10.0-6-amd64 x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
 __  __ _       _ _   _ _           
|  \/  (_)_ __ (_) | | (_)_   _____ 
| |\/| | | '_ \| | |_| | \ \ / / _ \
| |  | | | | | | |  _  | |\ V /  __/
|_|  |_|_|_| |_|_|_| |_|_| \_/ \___|
 
MiniHive v0.1

minihive@291614e93438:~$
```


Note that the SSH server, as well as the other services of Hadoop, HDFS, Hive, and Spark may take a few seconds to start. Wait a few seconds after you log in. If all services are running, then the command below should return **9**.

```console
minihive@291614e93438:~$ ps xa | grep java | wc
9
```

If the command above report a number different than 9, then, you can restart all services by calling this script:

```console
minihive@291614e93438:~$ /opt/restart-services.sh &
```

### Stop and Start the Docker container <a name="stop-and-start"></a>

Now, lets create a new empty file and exit the container.

```console
minihive@291614e93438:~$ touch my-file.txt
minihive@291614e93438:~$ exit
```

You can stop the container and start it again. You file ``my-file.txt'' should be there.

```console
foo@bar:~$ docker stop minihive
foo@bar:~$ docker start minihive
foo@bar:~$ ssh -p 2222 minihive@localhost
minihive@291614e93438:~$ ls
README.md  hadoop  hive  minihive  my-file.txt  radb  spark  tpch
```

### Copy files to/from your local machine <a name="copy-from-to"></a>

You can copy files to/from your local machine using scp.
Exemple:

- Copy to:
```console
foo@bar:~$ scp -P2222 -r <path-to-dir> minihive@localhost:
```

- Copy from:
```console
foo@bar:~$ scp -P2222 -r  minihive@localhost:<remote-path-to-dir> <local-path-to-dir>
```

### How to install extra software <a name="install-extra"></a>

You can install extra software with apt-get. This command install emacs.

```console
minihive@291614e93438:~$ sudo apt-get install emacs
```

# Running applications <a name="running-apps"></a>

This is the content of the miniHive Docker.
The directories *hadoop*, *hive*, *spark*, and *radb* contain sample data and example applications to be run in each system.
The *tpch* directory contains the [TPC-H](http://www.tpc.org/tpch/) benchmark that can be run on Hive.
Please, read the file *README.md* (in the HOME directory) for instructions on how to run example applications on Hadoop, Hive, Spark, RADB, and the miniHive project.

```console
minihive@291614e93438:~$ ls -lh
total 32K
drwxr-xr-x 2 minihive minihive 4.0K May 18 16:08 spark
drwxr-xr-x 2 minihive minihive 4.0K May 18 16:08 hive
-rw-r--r-- 1 minihive minihive 1.4K May 18 16:08 README.md
drwxr-xr-x 1 minihive minihive 4.0K May 18 16:08 radb
drwxr-xr-x 1 minihive minihive 4.0K May 18 16:08 minihive
drwxr-xr-x 7 minihive minihive 4.0K May 18 16:08 tpch
drwxr-xr-x 2 minihive minihive 4.0K May 18 16:08 hadoop
minihive@291614e93438:~$ less README.md
```

You can use the following commands to run examples on each system:

##### Hadoop

One example bundled with the Hadoop distribution is how to calculate the **Pi** number.
You can execute this example on Hadoop using the command below:

```console
minihive@291614e93438:~$ cd hadoop
minihive@291614e93438:~/hadoop$ hadoop jar hadoop-mapreduce-examples-3.2.2.jar pi 10 1000
```

Another examples is the wordcount problem. Use the commands below to compile and run the wordcount example.

```console
minihive@291614e93438:~/hadoop$ hdfs dfs -put starwars.txt
minihive@291614e93438:~/hadoop$ hdfs dfs -ls
Found 1 item
drwxr-xr-x   - minihive supergroup          0 2021-05-19 20:16 count
minihive@291614e93438:~/hadoop$ hadoop com.sun.tools.javac.Main WordCount.java
minihive@291614e93438:~/hadoop$ jar cf wc.jar WordCount*.class
minihive@291614e93438:~/hadoop$ hadoop jar wc.jar WordCount starwars.txt count
minihive@291614e93438:~/hadoop$ hdfs dfs -ls count/
Found 2 items
-rw-r--r--   1 minihive supergroup          0 2021-05-19 18:41 /tmp/count/_SUCCESS
-rw-r--r--   1 minihive supergroup       1054 2021-05-19 18:41 /tmp/count/part-r-00000
minihive@291614e93438:~/hadoop$ hdfs dfs -cat count/part*
[...]
zaps    1
zone    1
zoom    8
zooms   9
```

##### Hive

You can execute an example on Hive using the command below:

```console
minihive@291614e93438:~$ cd hive
minihive@291614e93438:~/hive$ hive -f students.ddl
minihive@291614e93438:~/hive$ hive -f students.sql
```

##### Spark

You can execute an example on Spark using the command below:

```console

minihive@291614e93438:~$ cd spark
minihive@291614e93438:~/spark$ spark-submit --class org.apache.spark.examples.SparkPi \
             --master local[2] \
             spark-examples_2.12-3.1.1.jar 100
```

##### RADB

You can execute an example on RADB using the command below:

```console
minihive@291614e93438:~$ cd radb
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

##### miniHive

The miniHive project, including the milestones with their unit tests are placed in the directory /home/minihive/minihive/.

```console
minihive@291614e93438:~$ cd minihive/
minihive@bb4f9da4ba8f:~/minihive$ ls -l
total 256
-rw-r--r-- 1 minihive minihive   1006 May 12 16:37 README.md
drwxr-xr-x 1 minihive minihive   4096 May 12 17:00 milestone1
drwxr-xr-x 2 minihive minihive   4096 May 12 16:37 milestone2
drwxr-xr-x 1 minihive minihive   4096 May 12 16:37 milestone3
drwxr-xr-x 2 minihive minihive   4096 May 12 16:37 milestone4
-rw-r--r-- 1 minihive minihive 239635 May 12 16:37 miniHiveSummary.pdf
```
