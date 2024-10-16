#!/bin/bash

cd $(dirname $0)

cp -r ../fiks-html/templates src/templates

docker run --rm -v $(pwd):/tmp/project \
  gitlab.fit.cvut.cz:5050/woowoo/woowoo:latest /bin/bash -c "/tmp/project/src/_build-html.sh"

res=$?

rm -r src/templates

exit $res
