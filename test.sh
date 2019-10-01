#!/bin/bash
set -o errexit
set -o nounset

# This is a testing domain set up in aptible.in, which resolves to 127.0.0.1
# (the dualstack aliases resolves there as well). Along with the port, it needs
# to be trusted in the Docker daemon as an insecure registry.
REGISTRY_BASE_NAME="test-docker-registry-all-in-one.aptible.in"
REGISTRY_PORT='12000'

IMG="$REGISTRY/$REPOSITORY:$TAG"

APP_CONTAINER="test-registry"
APP_DATA_CONTAINER="${APP_CONTAINER}-data"
TEST_CONTAINER="registry-canary"

docker run -i --rm "$IMG" bats /tmp/test

function cleanup {
  printf "\n\n\n"
  echo "==== DUMPING LOGS ===="
  docker logs "$APP_CONTAINER" || true
  printf "\n\n\n"
  echo "==== CLEANING UP  ===="
  docker rm -f "$APP_CONTAINER" "$APP_DATA_CONTAINER" "$TEST_CONTAINER" || true
}

trap cleanup EXIT
cleanup

# Initialize data container, and create cert.
docker create --name "$APP_DATA_CONTAINER" \
  -v "/var/lib/nginx" \
  -v "/etc/nginx/ssl" \
  "tianon/true"

docker run -it --rm --volumes-from "$APP_DATA_CONTAINER" "$IMG" \
  openssl req -x509 -batch -nodes -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/docker-registry-proxy.key \
  -out /etc/nginx/ssl/docker-registry-proxy.crt

# Then run the registry
REGISTRY_USER='aptible'
REGISTRY_PASS='foobar'

docker run -d --name "$APP_CONTAINER" --volumes-from "$APP_DATA_CONTAINER" \
  -e "AUTH_CREDENTIALS=${REGISTRY_USER}:${REGISTRY_PASS}" \
  -e "SERVER_NAME=${REGISTRY_BASE_NAME}" \
  -e "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/tmp/test-storage" \
  --publish "127.0.0.1:${REGISTRY_PORT}:443" \
  "$IMG"

for HOST_PREFIX in "" "dualstack-v1" "dualstack-v2"; do
  if [[ -n "$HOST_PREFIX" ]]; then
    REGISTRY_NAME="${HOST_PREFIX}-${REGISTRY_BASE_NAME}"
    TEST_REPO_NAME="aptible/alpine-as-${HOST_PREFIX}"
  else
    REGISTRY_NAME="$REGISTRY_BASE_NAME"
    TEST_REPO_NAME="aptible/alpine-as-default"
  fi

  TEST_IMAGE="${REGISTRY_NAME}:${REGISTRY_PORT}/${TEST_REPO_NAME}"

  echo "Testing ${TEST_IMAGE}"

  # Create a new test image from aptible/alpine, all the while checking that
  # it's big enough to force buffering.
  docker run --name "$TEST_CONTAINER" "aptible/alpine" sh -c 'head -c 524288 > /data'
  docker commit "$TEST_CONTAINER" "$TEST_IMAGE"
  docker rm "$TEST_CONTAINER"

  # We give the log in 10 attempts since the registry might take a little while
  # to come up we don't care if it fails, since we'll know when we fail the push.
  echo "Logging in"
  for _ in $(seq 1 10); do
    if docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASS" "${REGISTRY_NAME}:${REGISTRY_PORT}"; then
      break
    fi
    sleep 1
  done

  echo "Test push"
  docker push "$TEST_IMAGE"

  echo "Test pull"
  docker rmi "$TEST_IMAGE"
  docker pull "$TEST_IMAGE"

  echo "Test success for ${TEST_IMAGE}!"
done

# Now, we check that the prefixes addressed the right registries (and that the
# default did so as well).
docker logs "$APP_CONTAINER" 2>&1 | grep "PUT /v1/repositories/aptible/alpine-as-dualstack-v1"
docker logs "$APP_CONTAINER" 2>&1 | grep 'http.request.uri="/v2/aptible/alpine-as-dualstack-v2/blobs/uploads/"'

if [[ "$TAG" = 1 ]]; then
  docker logs "$APP_CONTAINER" 2>&1 | grep "PUT /v1/repositories/aptible/alpine-as-default"
else
  docker logs "$APP_CONTAINER" 2>&1 | grep 'http.request.uri="/v2/aptible/alpine-as-default/blobs/uploads/"'
fi

echo "Done!"
