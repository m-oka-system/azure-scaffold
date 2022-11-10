#!/bin/bash
set -e

# SSH サーバーがポート 2222 で立ち上がる
service ssh start

# Remove a potentially pre-existing server.pid for Rails.
rm -f /workspace/tmp/pids/server.pid

# 起動時にマイグレーションを実行する
if [[ $RAILS_ENV = 'production' ]]; then
  rails db:migrate
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
