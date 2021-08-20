#!/bin/bash

CURRENT_DIR="`pwd`";cd "`dirname \"$0\"`";SCRIPT_DIR="`pwd`";cd "$CURRENT_DIR"

source "$SCRIPT_DIR"/base
source "$SCRIPT_DIR"/config

DOCKER_BUILD_TAG_BASE="$DOCKER_ID/$DOCKER_REPOSITORY"
DOCKER_BUILD_TAG_CURRENT="$DOCKER_BUILD_TAG_BASE:${STORBACKUP_VERSION}_${DOCKER_IMAGE_VERSION}_$DOCKER_IMAGE_REVERSION"

CONTAINER_ID="`docker container ls|grep \"$DOCKER_BUILD_TAG_CURRENT\"|head -n1|awk '{print $1}'`"

if [ -n "$CONTAINER_ID" ]
then
  docker container stop "$CONTAINER_ID"
fi
