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
