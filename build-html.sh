#!/bin/bash

echo $(dirname $0)
cd $(dirname $0)

docker run -it --rm -v $(pwd):/tmp/project \
  gitlab.fit.cvut.cz:5050/woowoo/woowoo:latest /bin/bash -c "/tmp/project/src/_build-docker.sh"

# mv build ..
