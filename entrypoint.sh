#!/bin/sh

set -e

rm -f $APP_PATH/tmp/pids/server.pid

${@}