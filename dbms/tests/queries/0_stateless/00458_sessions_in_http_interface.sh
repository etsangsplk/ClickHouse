#!/usr/bin/env bash

#set -x

address='localhost'
port='8123'
url='http://'$address:$port'/'
session='?session_id=test_'$$
select="SELECT * FROM system.settings WHERE name = 'max_rows_to_read'"
curl="curl -sS"
table_name="tmp_table"

if ! $curl $url'?session_id=no_such_session&session_check=1' --data "$select" | grep -q Exception; then
    exit 1
fi
if $curl $url$session'&session_check=0' --data "$select" | grep -q Exception; then
    exit 1
fi

if ! $curl $url$session'&session_timeout=3601' --data "$select" | grep -q Exception; then
    exit 1
fi
if ! $curl $url$session'&session_timeout=-1' --data "$select" | grep -q Exception; then
    exit 1
fi
if $curl $url$session'&session_timeout=0' --data "$select" | grep -q Exception; then
    exit 1
fi
if $curl $url$session'&session_timeout=3600' --data "$select" | grep -q Exception; then
    exit 1
fi
if $curl $url$session'&session_timeout=60' --data "$select" | grep -q Exception; then
    exit 1
fi

$curl $url$session --data "SET max_rows_to_read=7777777"
if ! $curl $url$session --data "$select" | grep 7777777; then
    exit 1
fi

$curl $url$session --data "CREATE TEMPORARY TABLE $table_name (x String)"
$curl $url$session --data "INSERT INTO $table_name VALUES ('Hello'), ('World')"
if ! $curl $url$session --data "SELECT * FROM $table_name ORDER BY x" | grep 'Hello'; then
    exit 1
fi

if ! $curl $url'?session_id=another_session' --data "SELECT * FROM $table_name ORDER BY x" | grep -q "Table .* doesn't exist."; then
    exit 1
fi

( (
cat <<EOF
POST /$session HTTP/1.1
Host: $address:$port
Accept: */*
Content-Length: 62
Content-Type: application/x-www-form-urlencoded

EOF
sleep 1
) | telnet $address $port >/dev/null) 2>/dev/null &

if ! $curl $url$session --data "$select" | grep -q 'Exception'; then
    echo "Double access to the same session."
    exit 1
fi

session='?session_id=test_timeout_'$$

$curl $url$session'&session_timeout=1' --data "CREATE TEMPORARY TABLE $table_name (x String)"
$curl $url$session'&session_timeout=1' --data "INSERT INTO $table_name VALUES ('Hello'), ('World')"
if ! $curl $url$session'&session_timeout=1' --data "SELECT * FROM $table_name ORDER BY x" | grep 'Hello'; then
    exit 1
fi

sleep 4

if ! $curl $url$session'&session_check=1' --data "$select" | grep -q Exception; then
    echo 'Session did not expire on time.'
    exit 1
fi

$curl $url$session'&session_timeout=1' --data "CREATE TEMPORARY TABLE $table_name (x String)"
$curl $url$session'&session_timeout=1' --data "INSERT INTO $table_name VALUES ('Hello'), ('World')"
if ! $curl $url$session'&session_timeout=2' --data "SELECT * FROM $table_name ORDER BY x" | grep 'Hello'; then
    echo 'Session expired too early.'
    exit 1
fi

sleep 1

if ! $curl $url$session'&session_timeout=2' --data "SELECT * FROM $table_name ORDER BY x" | grep 'Hello'; then
    echo 'Session expired too early.'
    exit 1
fi

sleep 1

if ! $curl $url$session'&session_timeout=2' --data "SELECT * FROM $table_name ORDER BY x" | grep 'Hello'; then
    echo 'Session expired too early.'
    exit 1
fi

sleep 4

if ! $curl $url$session'&session_check=1' --data "$select" | grep -q Exception; then
    echo 'Session did not expire on time.'
    exit 1
fi

echo
echo "All tests PASSED."
