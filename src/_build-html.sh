#!/bin/bash

# expects sources in /tmp/project, builds in /tmp/build

# move source
mkdir -p /tmp/build
rsync --recursive -L /tmp/project/src/* /tmp/build/

# copy templates
# cp -r templates /tmp/build/

# build html
cd /tmp/build
rake fikshtml:assets fikshtml:build

res=$?

# copy build
mkdir -p /tmp/project/build
cp -r build/fiks-html /tmp/project/build/

exit $res
