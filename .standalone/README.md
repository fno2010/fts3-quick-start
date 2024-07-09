# Standalone FTS3 Container Image

This is a standalone fts3 docker environment setup which is compatible with the latest [rucio container environment](https://github.com/rucio/containers).

## Build Image

~~~ sh
## Locate your fts3 source code directory
## If you don't have one, just clone it
$ git clone https://github.com/cern-fts/fts3

## Clone this repo
$ git clone https://github.com/fno2010/fts3-quick-start

## Copy the .standalone directory to the fts3 source code directory
$ cp -r fts3-quick-start/.standalone fts3/

## Go to the .standalone directory
$ cd fts3/.standalone

## Fetch dependent files from the rucio containers repo
$ git clone https://github.com/rucio/containers

## Switch to the parent directory
$ cd ..

## Build the docker image
$ docker build -t myrepo/fts -f .standalone/Dockerfile .
~~~

## Use Image in Rucio Container Setup

Modify `fts` service of `/etc/docker/dev/docker-compose.yml`:

~~~ yaml
  fts:
    # ...
    image: myrepo/fts
    # ...
    volumes:
      # ...
      - <PATH_TO_MY_FTS_DIR>:/fts3
    # ...
~~~

## Build and Reinstall FTS3 from the Source Code

~~~ sh
## Enter the fts3 container
$ docker-compose -p dev exec fts bash

## Rebuild and Reinstall fts3
$ /fts3/.standalone/tools/reinstall
~~~

## Restart FTS3 Server

~~~ sh
$ /fts3/.standalone/tools/restart
~~~
