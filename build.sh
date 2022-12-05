#!/bin/sh
docker pull alpine:latest
docker build --network host -t tgas .
