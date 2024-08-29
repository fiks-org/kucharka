#!/bin/bash

cd $(dirname $0)

cp -r ../fiks-html/templates src/templates

docker run -it --rm -v $(pwd):/tmp/project \
  gitlab.fit.cvut.cz:5050/woowoo/woowoo:latest /bin/bash -c "/tmp/project/src/_build-html.sh"

rm -r src/templates
# mv build ..
