#!/bin/bash

set -e

curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh
./bin/grype --fail-on=medium  --only-fixed --config=.circleci/.anchore/grype.yaml -vv $IMAGE_NAME
