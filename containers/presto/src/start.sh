#! /usr/bin/env bash

_log() {
  [[ "$2" ]] && echo "[`date +'%Y-%m-%d %H:%M:%S.%N'`] - $1 - $2"
}

info() {
  [[ "$1" ]] && _log "INFO" "$1"
}

warn() {
  [[ "$1" ]] && _log "WARN" "$1"
}

# make all all environment variables are set.
validate_env() {
	[ -z "$PRESTO_ISCOORDINATOR" ] && echo "Need to set PRESTO_ISCOORDINATOR" && exit 1;
	[ -z "$Fabric_NodeIPOrFQDN" ] && echo "Need to set Fabric_NodeIPOrFQDN" && exit 1;
}

# Setup all variable for the config
setup_env() {
  # check environment variables and set defaults as required
  : ${SERV_PORT:="8080"}
  : ${SERV_URI:="http://$Fabric_NodeIPOrFQDN:$SERV_PORT"}
  : ${NODE_ENV:="production"}
  : ${NODE_ID:="`python -c 'import uuid; print uuid.uuid1()'`"}
  : ${CONF_DIR:="/usr/local/presto/etc"}
  : ${DATA_DIR:="/usr/local/presto/data"}
}

setup_config() {
  if [ ! -f $CONF_DIR/node.properties ]; then
    echo "node.properties not found, generate one with default settings..."
    echo "node.environment=$NODE_ENV" > $CONF_DIR/node.properties
    echo "node.id=$NODE_ID" >> $CONF_DIR/node.properties
    echo "node.data-dir=/presto/data" >> $CONF_DIR/node.properties
    cat $CONF_DIR/node.properties
  else
    sed -ri 's/^(node.environment=).*/\1'"$NODE_ENV"'/' "$CONF_DIR/node.properties"
    sed -ri 's|^(node.data-dir=).*|\1'"/presto/data"'|' "$CONF_DIR/node.properties"
  fi
  
  if [ ! -f $CONF_DIR/jvm.config ]; then
    echo "jvm.config not found, generate one with default settings..."
    echo "-server" > $CONF_DIR/jvm.config
    echo "-Xmx2G" >> $CONF_DIR/jvm.config
    echo "-XX:+UseG1GC" >> $CONF_DIR/jvm.config
    echo "-XX:G1HeapRegionSize=32M" >> $CONF_DIR/jvm.config
    echo "-XX:+UseGCOverheadLimit" >> $CONF_DIR/jvm.config
    echo "-XX:+ExplicitGCInvokesConcurrent" >> $CONF_DIR/jvm.config
    echo "-XX:+HeapDumpOnOutOfMemoryError" >> $CONF_DIR/jvm.config
#    echo "-XX:OnOutOfMemoryError=kill -9 %p" >> $CONF_DIR/jvm.config
    echo "-XX:OnOutOfMemoryError=kill -9 0" >> $CONF_DIR/jvm.config
    cat $CONF_DIR/jvm.config
  fi

  if [ ! -f $CONF_DIR/config.properties ]; then
    echo "config.properties not found, generate one for worker node..."
    echo "query.max-memory=4GB" > $CONF_DIR/config.properties
    echo "query.max-memory-per-node=1GB" >> $CONF_DIR/config.properties
    echo "http-server.http.port=8080" >> $CONF_DIR/config.properties
    echo "discovery.uri=$SERV_URI" >> $CONF_DIR/config.properties
	if [ "$PRESTO_ISCOORDINATOR" == "true" ]; then
		echo "coordinator=true" >> $CONF_DIR/config.properties
		echo "discovery-server.enabled=true" >> $CONF_DIR/config.properties
		echo "node-scheduler.include-coordinator=false" >> $CONF_DIR/config.properties
	else
		echo "coordinator=false" >> $CONF_DIR/config.properties
	fi
    cat $CONF_DIR/config.properties
  else
    sed -ri 's/^(http-server.http.port=).*/\1'"8080"'/' "$CONF_DIR/config.properties"
    sed -ri 's|^(discovery.uri=).*|\1'"$SERV_URI"'|' "$CONF_DIR/config.properties"
  fi

  if [ ! -f $CONF_DIR/log.properties ]; then
    echo "log.properties not found, generate one with default settings..."
    echo "com.facebook.presto=INFO" > $CONF_DIR/log.properties
    cat $CONF_DIR/log.properties
  fi

  if [ ! -d $CONF_DIR/catalog ]; then
    echo "no catalog found, create one for jmx..."
    mkdir -p $CONF_DIR/catalog
    echo "connector.name=jmx" > $CONF_DIR/catalog/jmx.properties
    cat $CONF_DIR/catalog/jmx.properties
  fi

  if [ -d $DATA_DIR ]; then
    info "Reuse existing data directory: $DATA_DIR"
  else
    info "Initialize data directory: $DATA_DIR"
    mkdir -p $DATA_DIR
  fi
}

start_presto() {
	/usr/local/presto/bin/launcher run
}

main() {
  validate_env
  setup_env
  setup_config
  start_presto
}

main "$@"