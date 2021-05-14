# MiniHive Docker

This is the minihive Docker.

# Building

## Building the Docker image

You can build the docker image with the commands below.
The docker will install and configure all required services to run MiniHive.

```sh
git clone https://git.fim.uni-passau.de/sdbs/minihive/minihive-docker.git
docker build -t minihive-docker .
```

## Running the Docker container

You need to create a container with the following command.

```sh
docker run -t -d --name minihive -p 2222:22 minihive-docker
```

At this point you have the docker container running in the background.

## Accessing the Docker container

The container name is ``minihive''.
To access it you can connect via ssh accessing the localhost port 2222.

The user name and password is:

- login: minihive
- password: minihive

This user has sudo rights.
Note that it may take some seconds until the sshd is available.

```sh
ssh -p 2222 minihive@localhost
```

## Copy files to/from your local machine

You can copy files to/from your local machine using scp.
Exemple:

- Copy to:
```sh
scp -P2222 -r <my-code-dir> minihive@localhost:
```

- Copy from:
```sh
scp -P2222 -r  minihive@localhost:<code-dir> <local-path>
```

## Stop and Start the Docker container

Now, lets create a new file and save it to the container.
You create one empty file and exit the container.

```sh
touch my-file.txt
exit
```

You can stop the container and start it again. You file ``my-file.txt'' should be there.

```
docker stop minihive
docker start minihive
```

## How to install extra software

You can install extra software with apt-get. This example install emacs.

```sh
sudo apt-get install emacs
```

## Running applications

The file ${HOME}/README.md has instructions to run applications on Hadoop, Hive, Spark, RADB, and the MiniHive.

## What is installed

- Hadoop (3.2.2)
- Hive (3.1.2)
- Spark (3.1.1)
- PostgreSQL (13)

- radb
- luigi
- sqlparse

- Python 3
- Java 8 and 11

## What is not installed

- Graphical User Interface
- A Graphical IDE

## Docker Documentation

Please check the [Docker commmand line reference](https://docs.docker.com/engine/reference/commandline/docker/) for additional information.
