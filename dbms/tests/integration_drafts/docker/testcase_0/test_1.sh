#!/bin/bash
set -e

[[ `id -u -n` -ne root ]] && su

docker-compose exec -T ch1 clickhouse-client -q "CREATE TABLE IF NOT EXISTS all_tables ON CLUSTER 'cluster_no_replicas'
    (database String, name String, engine String, metadata_modification_time DateTime)
    ENGINE = Distributed('cluster_no_replicas', 'system', 'tables')" | cut -f 1 | uniq | wc -l

# Test default_database
docker-compose exec -T ch1 clickhouse-client -q "CREATE DATABASE IF NOT EXISTS test2 ON CLUSTER 'cluster'" 1>/dev/null
docker-compose exec -T ch1 clickhouse-client -q "CREATE TABLE null ON CLUSTER 'cluster2' (i Int8) ENGINE = Null" 1>/dev/null
docker-compose exec -T ch1 clickhouse-client -q "SELECT hostName() AS h, database FROM all_tables WHERE name = 'null' ORDER BY h"
docker-compose exec -T ch1 clickhouse-client -q "DROP TABLE IF EXISTS null ON CLUSTER cluster2" 1>/dev/null

echo

# Replicated alter
docker-compose exec -T ch1 clickhouse-client -q "CREATE TABLE merge ON CLUSTER cluster (p Date, i Int32)
    ENGINE = ReplicatedMergeTree('/clickhouse/tables/{layer}-{shard}/hits', '{replica}', (p, p), 1)" 1>/dev/null
docker-compose exec -T ch1 clickhouse-client -q "CREATE TABLE all_merge_1 ON CLUSTER cluster (p Date, i Int64)
    ENGINE = Distributed(cluster, default, merge)" 1>/dev/null
docker-compose exec -T ch1 clickhouse-client -q "INSERT INTO all_merge_1 (i) VALUES (1) (2)"
docker-compose exec -T ch1 clickhouse-client -q "ALTER TABLE merge ON CLUSTER cluster MODIFY COLUMN i Int64" | cut -f 1-2 | sort

echo

# Server fail
docker-compose kill ch2 1>/dev/null 2>/dev/null
(docker-compose exec -T ch1 clickhouse-client -q "CREATE DATABASE IF NOT EXISTS test2 ON CLUSTER 'cluster'" | cut -f 1-2 | sort) &
sleep 1
docker-compose start ch2 1>/dev/null 2>/dev/null
wait

echo

# Network fail
docker-compose pause ch2 zoo1 1>/dev/null 2>/dev/null
(docker-compose exec -T ch1 clickhouse-client -q "CREATE DATABASE IF NOT EXISTS test2 ON CLUSTER 'cluster'" | cut  -f 1-2 | sort) &
sleep 10
docker-compose unpause ch2 zoo1 1>/dev/null 2>/dev/null
wait
