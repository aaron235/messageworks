#!/bin/bash
(mongod --dbpath db --smallfiles --logpath log/mongodb.log) &
(morbo -v server.pl) &
