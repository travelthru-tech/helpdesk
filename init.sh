#!/bin/bash

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd frappe-bench
else
    echo "Creating new bench..."
    bench init --skip-redis-config-generation frappe-bench --version version-15
    cd frappe-bench

    # Use containers instead of localhost
    bench set-mariadb-host mariadb
    bench set-redis-cache-host redis://redis:6379
    bench set-redis-queue-host redis://redis:6379
    bench set-redis-socketio-host redis://redis:6379

    # Remove redis, watch from Procfile (they are handled by docker)
    sed -i '/redis/d' ./Procfile
    sed -i '/watch/d' ./Procfile

    bench get-app helpdesk --branch main

    bench new-site desk.travelthru.com \
    --force \
    --mariadb-root-password r00T@!travelthru \
    --admin-password r00T@!travelthru \
    --no-mariadb-socket

    bench --site desk.travelthru.com install-app helpdesk
    bench --site desk.travelthru.com set-config developer_mode 1
    bench --site desk.travelthru.com set-config mute_emails 1
    bench --site desk.travelthru.com set-config server_script_enabled 1
fi

# always clear cache and force rebuild the frontend before starting
cd /home/frappe/frappe-bench
bench --site desk.travelthru.com clear-cache
bench build --app helpdesk --force
bench use desk.travelthru.com

# start bench
exec bench start
