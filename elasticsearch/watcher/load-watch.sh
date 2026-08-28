#!/usr/bin/env bash
# Loads the high-error-rate Watcher into Elasticsearch. If SLACK_WEBHOOK_URL
# is set, the watch also posts to Slack when it fires; otherwise it only
# logs to the Watcher history (same as PUTting high-error-rate-watch.json
# directly).
#
# Usage:
#   ./load-watch.sh                                   # logging-only action
#   SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..." ./load-watch.sh
#
# Requires: curl, jq
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
watch_file="$script_dir/high-error-rate-watch.json"
es_url="${ELASTICSEARCH_URL:-http://localhost:9200}"

# Watcher is an X-Pack feature not included in Elasticsearch's default Basic
# license, so a fresh cluster rejects watch PUTs with a 403
# "non-compliant for [watcher]" security_exception. Start (or no-op resume)
# the 30-day trial license so this works out of the box.
license_type=$(curl -sf "$es_url/_license" | grep -o '"type" *: *"[a-z]*"' | head -1 | grep -o '[a-z]*"$' | tr -d '"')
if [[ "$license_type" != "trial" && "$license_type" != "platinum" && "$license_type" != "enterprise" ]]; then
  echo "License is '$license_type'; starting a trial license so Watcher is available..." >&2
  curl -s -X POST "$es_url/_license/start_trial?acknowledge=true" > /dev/null
fi

if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
  # Split "https://hooks.slack.com/services/T000/B000/XXXX" into host + path
  # so the watch's webhook action never needs the full URL/token inlined
  # into the committed JSON file.
  no_scheme="${SLACK_WEBHOOK_URL#https://}"
  host="${no_scheme%%/*}"
  path="/${no_scheme#*/}"

  payload=$(jq --arg host "$host" --arg path "$path" '
    .actions.notify_slack = {
      "webhook": {
        "scheme": "https",
        "host": $host,
        "port": 443,
        "method": "POST",
        "path": $path,
        "headers": { "Content-Type": "application/json" },
        "body": "{\"text\": \":rotating_light: High error rate: {{ctx.payload.hits.total}} ERROR events in the last 5 minutes\"}"
      }
    }
  ' "$watch_file")
  echo "Loading watch with Slack notification action..."
else
  payload=$(cat "$watch_file")
  echo "SLACK_WEBHOOK_URL not set; loading watch with logging-only action." >&2
fi

response=$(curl -s -w '\n%{http_code}' -X PUT "$es_url/_watcher/watch/high-error-rate" \
  -H "Content-Type: application/json" \
  -d "$payload")
status="${response##*$'\n'}"
body="${response%$'\n'*}"
echo "$body"
if [[ "$status" -ge 400 ]]; then
  echo "Failed to load watch (HTTP $status)" >&2
  exit 1
fi
