#!/bin/bash

version=$(cat `pwd`/package.json | json version)
name=$(cat `pwd`/package.json | json name)
org=$(cat `pwd`/package.json | json organisation)
tag=latest
publish=0

usage() {

cat << EOF
Usage: docker-build-with-meta -t latest -n projectname -p

Build docker image using meta information from git and package.json and
optionally publish to docker hub registry.

All arguments are optional:

  -t TAG     project tag (default to latest)
  -n PROJECT project name (default to what specified in package.json)
  -p         whether publish to registry (not published when omitted)
  -h         display usage info

EOF

}

while getopts "hpt:n:" opt; do
  case $opt in
    n)
      name=$OPTARG
      ;;
    t)
      tag=$OPTARG
      ;;
    p)
      publish=1
      ;;
    h)
      usage >&2
      exit 1
  esac
done

set -e

active=$(docker-machine active)

isSwarm=$(docker-machine inspect $active | json HostOptions.SwarmOptions.IsSwarm)

if [[ "true" == "$isSwarm" ]]
then
  chalk -t "{red Attempt to build on swarm.} Switch to {bold dev machine} to build."
  exit 1
fi


chalk -t "Building {green $org/$name:{bold $tag}} version {blue.bold $version} using {blue.bold $active} docker machine"

docker build -t $org/$name:$tag \
  --label "version=$version" \
  --label "commit-msg=`git log -1 --pretty=%s`" \
  --label "commit-sha=`git rev-parse --short HEAD`" \
  --label "commit-author=`git log -1 --pretty='%an <%ae>'`" \
  --label "release-date=`date -u '+%Y-%m-%d %H:%M %Z'`" \
  --label "released-by=`git config --get user.name`" \
  `pwd`

if [[ "$publish" == "1" ]]
then
  echo ""
  chalk -t "{red Publishing {green $org/$name:{bold $tag}} image to registry}"
  docker push $org/$name:$tag
fi

