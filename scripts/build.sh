#!/bin/bash
current=${PWD##*/}
cd ./build
cmake ..
make
./$current
