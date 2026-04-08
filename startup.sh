#!/bin/sh
# -------------------------- #
# Author: ADAM M 
# WEZVATECH - +91-9739110917
# -------------------------- #

set -e 
echo "Setting the configuration file application to start .."
cat /opt/wezva/application.properties.orig > application.properties
cat /vault/secrets/databaseenv.txt >> application.properties

echo "Starting Wezvatech Springboot application ..."
echo "command: java -jar app.jar $@"
exec java -jar app.jar "$@"
