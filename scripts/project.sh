#!/bin/bash
mkdir $1
mkdir ./$1/build
mkdir ./$1/src
touch ./$1/CMakeLists.txt
echo "Project $1 has been created"
