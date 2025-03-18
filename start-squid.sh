#!/bin/bash

tail -vn 0 -F /var/log/squid/{access,cache,error,store}.log &

# in case of using cache dir, we need to initialize it
squid -d 1 --foreground -f /etc/squid/squid.conf -z

# now start the squid primary process with supplied options
squid -d 1 --foreground -f /etc/squid/squid.conf $@
