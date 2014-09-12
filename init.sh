#!/bin/bash
mongod --dbpath db --smallfiles --logpath log/mongodb.log >> log/mongod.log &
morbo -l http://*:3000 server.pl >> log/morbo.log &
