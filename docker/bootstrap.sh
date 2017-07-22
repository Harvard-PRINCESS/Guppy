#!/bin/bash

wget -O fvp.tgz http://bit.ly/2ukxvSj
tar -xvf fvp.tgz
docker build . -t fvp


