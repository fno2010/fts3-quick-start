#!/bin/bash

source env.sh

BASEDIR=$(dirname "$(readlink -f "$0")")


prepare_docker_compose () {
    echo "Creating FTS/Rucio docker compose file from the template..."
    envsubst < $BASEDIR/native/docker-compose.template.yml > $BASEDIR/native/docker-compose.yml
    echo "Done"

    echo "Creating XRootD docker compose file from the template for xrd1..."
    envsubst < $BASEDIR/native/docker-compose-xrd1.template.yml > $BASEDIR/native/docker-compose-xrd1.yml
    echo "Copying necessary files to the xrd1 host..."
    scp -r $BASEDIR/native/ $SSH_USER@$XRD1_HOST:~/native/
    echo "Done"

    echo "Creating XRootD docker compose file from the template for xrd2..."
    envsubst < $BASEDIR/native/docker-compose-xrd2.template.yml > $BASEDIR/native/docker-compose-xrd2.yml
    echo "Copying necessary files to the xrd2 host..."
    scp -r $BASEDIR/native/ $SSH_USER@$XRD2_HOST:~/native/
    echo "Done"

    echo "Creating XRootD docker compose file from the template for xrd3..."
    envsubst < $BASEDIR/native/docker-compose-xrd3.template.yml > $BASEDIR/native/docker-compose-xrd3.yml
    echo "Copying necessary files to the xrd3 host..."
    scp -r $BASEDIR/native/ $SSH_USER@$XRD3_HOST:~/native/
    echo "Done"
}


start_docker_compose () {
    echo "Starting FTS/Rucio containers..."
    docker-compose -f $BASEDIR/native/docker-compose.yml up -d

    echo "Starting container on xrd1..."
    ssh -l $SSH_USER $XRD1_HOST docker-compose -f ~/native/docker-compose-xrd1.yml up -d

    echo "Starting container on xrd2..."
    ssh -l $SSH_USER $XRD2_HOST docker-compose -f ~/native/docker-compose-xrd2.yml up -d

    echo "Starting container on xrd3..."
    ssh -l $SSH_USER $XRD3_HOST docker-compose -f ~/native/docker-compose-xrd3.yml up -d
}


stop_docker_compose () {
    echo "Stopping FTS/Rucio containers..."
    docker-compose -f $BASEDIR/native/docker-compose.yml stop

    echo "Stopping container on xrd1..."
    ssh -l $SSH_USER $XRD1_HOST docker-compose -f ~/native/docker-compose-xrd1.yml stop

    echo "Stopping container on xrd2..."
    ssh -l $SSH_USER $XRD2_HOST docker-compose -f ~/native/docker-compose-xrd2.yml stop

    echo "Stopping container on xrd3..."
    ssh -l $SSH_USER $XRD3_HOST docker-compose -f ~/native/docker-compose-xrd3.yml stop
}


init_fts () {
    echo $FTS_NODE
    # docker-compose -p $COMPOSE_PROJECT exec $RUCIO_NODE xrdgsiproxy init -bits 2048 -valid 9999:00 -cert /opt/rucio/etc/usercert.pem  -key /opt/rucio/etc/userkey.pem
    docker-compose -p $COMPOSE_PROJECT exec $FTS_NODE fts-rest-whoami -v -s https://$FTS_HOST:8446
    docker-compose -p $COMPOSE_PROJECT exec $FTS_NODE fts-rest-delegate -vf -s https://$FTS_HOST:8446 -H 9999
}

connect_fts () {
    docker-compose -p $COMPOSE_PROJECT exec $FTS_NODE bash
}

dump_fts_log () {
    docker-compose -p $COMPOSE_PROJECT exec $FTS_NODE bash -c "cat /var/log/fts3/fts3server.log"
}

connect_ftsdb () {
    docker-compose -p $COMPOSE_PROJECT exec $FTSDB_NODE bash -c 'MYSQL_PWD=fts mysql -u fts fts'
}

gen_test_file () {
    local target_se=$1
    local filename=$2
    local filesize=$3
    ssh -l $SSH_USER $target_se docker exec -ti $target_se mkdir -p /rucio
    ssh -l $SSH_USER $target_se docker exec -ti $target_se dd if=/dev/urandom of=/rucio/$filename bs=1M count=$filesize
}

submit_test_transfers () {
    local source_se=$1
    local dest_se=$2
    local filename=$3
    docker-compose -p $COMPOSE_PROJECT exec $FTS_NODE fts-rest-transfer-submit -v -s https://$FTS_HOST:8446 root://$source_se//rucio/$filename root://$dest_se//rucio/$filename
}

clean_up_storage () {
    local target_se=$1
    ssh -l $SSH_USER $target_se docker exec -ti $target_se bash -c 'rm /rucio/*'
}

gen_batch_files () {
    local target_se=$1
    local filesize=$2
    local filenum=$3
    local start=${4:-1}
    local prefix=${5:-test}
    let end=start+filenum-1

    for i in `seq $start $end`
    do
        gen_test_file $target_se $prefix$i $filesize
    done
}

submit_batch_transfer () {
    local source_se=$1
    local dest_se=$2
    local filenum=$3
    local start=${4:-1}
    local prefix=${5:-test}
    let end=start+filenum-1

    for i in `seq $start $end`
    do
        submit_test_transfers $source_se $dest_se $prefix$i
    done
}

dump_optimizer_hist () {
    local sql_stmt='select * from t_optimizer_evolution where datetime > '"'"$1"'"
    docker-compose -p $COMPOSE_PROJECT exec $FTSDB_NODE bash -c 'echo "'"$sql_stmt"'" | mysql -u fts --password=fts fts'
}

dump_transfer_hist () {
    local sql_stmt='select * from t_file where start_time > '"'"$1"'"
    docker-compose -p $COMPOSE_PROJECT exec $FTSDB_NODE bash -c 'echo "'"$sql_stmt"'" | MYSQL_PWD=fts mysql -u fts fts'
}

dump_job_hist () {
    local sql_stmt='select * from t_file'
    docker-compose -p $COMPOSE_PROJECT exec $FTSDB_NODE bash -c 'echo "'"$sql_stmt"'" | MYSQL_PWD=fts mysql -u fts fts'
}

config_fts_link () {
    set -f
    local source_se=$1
    local dest_se=$2
    local min_active=$3
    local max_active=$4
    local opt_mode=${5:-2}
    local sql_stmt="insert into t_link_config (source_se, dest_se, symbolic_name, min_active, max_active, optimizer_mode) values ('$source_se', '$dest_se', '$source_se-$dest_se', $min_active, $max_active, $opt_mode)"
    sql_stmt="$sql_stmt; select * from t_link_config"
    docker-compose -p $COMPOSE_PROJECT exec $FTSDB_NODE bash -c 'MYSQL_PWD=fts mysql -u fts -e "'"$sql_stmt"'" fts'
    set +f
}

update_fts_link () {
    set -f
    local source_se=$1
    local dest_se=$2
    local min_active=$3
    local max_active=$4
    local opt_mode=${5:-2}
    local sql_stmt="update t_link_config set min_active='$min_active', max_active='$max_active', optimizer_mode='$opt_mode' where source_se='$source_se' AND dest_se='$dest_se'"
    sql_stmt="$sql_stmt; select * from t_link_config"
    docker-compose -p $COMPOSE_PROJECT exec $FTSDB_NODE bash -c 'MYSQL_PWD=fts mysql -u fts -e "'"$sql_stmt"'" fts'
    set +f
}

show_fts_link_config () {
    set -f
    local sql_stmt="select * from t_link_config"
    docker-compose -p $COMPOSE_PROJECT exec $FTSDB_NODE bash -c 'MYSQL_PWD=fts mysql -u fts -e "'"$sql_stmt"'" fts'
    set +f
}

config_optimizer () {
    local source_se=$1
    local dest_se=$2
    local active=$3
    local msg='{"source_se":"'$source_se'","dest_se":"'$dest_se'","active":'$active'}'
    docker-compose -p $COMPOSE_PROJECT exec $FTS_NODE curl --capath /etc/grid-security/certificates -H "Content-Type: application/json" -d "$msg" https://fts:8446/optimizer/current
}

