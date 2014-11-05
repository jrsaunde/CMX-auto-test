# Docker file v1 for CMX server

#Build from base ubuntu version 14.04
FROM ubuntu:14.04

#Author yo
MAINTAINER Jamie Saunders <jrsaunde@ncsu.edu>

#Don't install gem docs
RUN echo 'gem: --no-document' > /usr/local/etc/gemrc

#Install ruby and build-essential
RUN apt-get update && apt-get install -y ruby ruby-dev build-essential libsqlite3-dev

#Necessary gems we need to run app
RUN gem install sinatra sinatra-redirect-with-flash sequel sqlite3 rack-flash3 json rack-google-analytics

#Add the project
ADD . /project

#Setup working directory
WORKDIR /project

#We use this port
EXPOSE 55556


