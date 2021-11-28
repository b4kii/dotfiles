#!/bin/bash
mkdir $1
cd $1
printf 'cmake_minimum_required()
project()
add_executable()
target_compile_features()
target_compile_options()' > CMakeLists.txt
mkdir ./build
mkdir ./src
echo "Project '"$1"' has been created"
mkdir $1
mkdir ./$1/build
mkdir ./$1/src
touch ./$1/CMakeLists.txt
echo "Project $1 has been created"
