# Docker file v1 for CMX server
FROM ubuntu:14.04
MAINTAINER Jamie Saunders <jrsaunde@ncsu.edu>
RUN apt-get update && apt-get install -y ruby ruby-dev build-essential
RUN gem install sinatra sinatra-redirect-with-flash sequel rack-flash3 json rack-google-analytics
