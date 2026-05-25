#!/bin/sh
# Playhub startup script for Linux ARM64 / AMD64
# Usage: ./start.sh [port]

set -e

PORT="${1:-18080}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JAR_FILE="$SCRIPT_DIR/playhub/target/tvbox-webapp-1.0.0.jar"
CONFIG_FILE="$SCRIPT_DIR/docker/application.yml"

# Detect available memory and set heap accordingly
# Minimum safe heap for low-memory devices (e.g. 1GB RAM total)
TOTAL_MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "1048576")
TOTAL_MEM_MB=$(( TOTAL_MEM_KB / 1024 ))

if [ "$TOTAL_MEM_MB" -le 512 ]; then
    HEAP_MAX="192m"
    HEAP_MIN="32m"
elif [ "$TOTAL_MEM_MB" -le 1024 ]; then
    HEAP_MAX="384m"
    HEAP_MIN="64m"
elif [ "$TOTAL_MEM_MB" -le 2048 ]; then
    HEAP_MAX="768m"
    HEAP_MIN="128m"
else
    HEAP_MAX="1024m"
    HEAP_MIN="128m"
fi

echo "Total system memory: ${TOTAL_MEM_MB} MB"
echo "JVM heap: -Xms${HEAP_MIN} -Xmx${HEAP_MAX}"
echo "Server port: ${PORT}"
echo ""

JAVA_OPTS="${JAVA_OPTS:--Xms${HEAP_MIN} -Xmx${HEAP_MAX}}"
JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
JAVA_OPTS="$JAVA_OPTS -XX:+ExitOnOutOfMemoryError"
JAVA_OPTS="$JAVA_OPTS -XX:+UseStringDeduplication"
JAVA_OPTS="$JAVA_OPTS -Dserver.port=$PORT"
JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF-8"

CONFIG_ARG=""
if [ -f "$CONFIG_FILE" ]; then
    CONFIG_ARG="--spring.config.additional-location=file:$CONFIG_FILE"
fi

exec java $JAVA_OPTS -jar "$JAR_FILE" $CONFIG_ARG "$@"
