# Standalone FTS3 Container Image

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

## Build the docker image
$ docker build -t myrepo/fts .
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
      - path_to_my_fts_dir:/fts3
    # ...
~~~
