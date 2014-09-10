#!/bin/bash
mongod --dbpath $HOME/server/db --smallfiles --logpath $HOME/server/log/mongod.log;
morbo -l http://*:8080 -v $HOME/server/server.pl;
