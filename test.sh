#!/bin/bash
set -o errexit
set -o nounset

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
REGISTRY_PORT='12000' # This needs to be trusted as an insecure registry in the daemon
docker run -d --name "$APP_CONTAINER" --volumes-from "$APP_DATA_CONTAINER" \
  -e "AUTH_CREDENTIALS=${REGISTRY_USER}:${REGISTRY_PASS}" \
  --publish "127.0.0.1:${REGISTRY_PORT}:443" \
  "$IMG"

REGISTRY_NAME="127.0.0.1:${REGISTRY_PORT}"
TEST_REPO="aptible/alpine"
TEST_IMAGE="${REGISTRY_NAME}/${TEST_REPO}"

# Make sure our test repo is big enough to force buffering
docker run --name "$TEST_CONTAINER" "$TEST_REPO" sh -c 'head -c 524288 > /data'
docker commit "$TEST_CONTAINER" "$TEST_IMAGE"

# We give the log in 10 attempts since the registry might take a little while
# to come up we don't care if it fails, since we'll know when we fail the push.
echo "Logging in"
for _ in $(seq 1 10); do
  if docker login -e "foo@example.org" -u "$REGISTRY_USER" -p "$REGISTRY_PASS" "$REGISTRY_NAME"; then
    break
  fi
  sleep 1
done

echo "Test push"
docker push "$TEST_IMAGE"

echo "Test pull"
docker rmi "$TEST_IMAGE"
docker pull "$TEST_IMAGE"

echo "Done!"
