#!/bin/bash

print_info() {
  lightgreen='\e[92m'
  nocolor='\033[0m'
  echo -e "${lightgreen}[*] $1${nocolor}"
}

print_info "Making all bash scripts executable"

find . -type f -iname "*.sh" -exec chmod +x {} \;

# Select the version you prefer, or both (16.04 18.04)
TAG=latest
for VERSION in 18.04
do

  print_info "Publishing base image"

  cd ubuntu$VERSION-base

  docker push ravensorb/devopsubuntu$VERSION:$TAG

  cd ..

  print_info "Publishing Python image"

  cd ubuntu$VERSION-python

  docker push ravensorb/devopsubuntu$VERSION-python:$TAG

  cd ..

  print_info "Publishing Docker inception image"

  cd ubuntu$VERSION-docker

  docker push ravensorb/devopsubuntu$VERSION-docker:$TAG

  cd ..

  print_info "Publishing .NET Core image"

  cd ubuntu$VERSION-dotnet

  docker push ravensorb/devopsubuntu$VERSION-dotnet:$TAG

  cd ..

  print_info "Publishing Node.js image"

  cd ubuntu$VERSION-nodejs

  docker push ravensorb/devopsubuntu$VERSION-nodejs:$TAG

  cd ..
done
