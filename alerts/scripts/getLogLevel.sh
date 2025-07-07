#!/bin/bash

# Variables
ES_HOST="http://localhost:9200"
KIBANA_HOST="http://localhost:5601"
INDEX_PATTERN="vector-tubt*"
ELASTIC_USER="elastic"
ELASTIC_PASSWORD="xxxxxxxxxxxxxxxxxxxxx"
query_time="now-1m"  # Last 1 minutes
DISCORD_CHANNEL_ID="xxxxxxxxxxxxxxxxxxx"
DISCORD_BOT_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
STATE_FILE="/mnt/.last_state"

# Get Service Name
SERVICE_NAMES=$(curl -s -u $ELASTIC_USER:$ELASTIC_PASSWORD -X POST "$ES_HOST/$INDEX_PATTERN/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "services": {
        "terms": {
          "field": "service.name.keyword",
          "size": 1000
        }
      }
    }
  }' | jq -r '.aggregations.services.buckets[].key')

# Query Elasticsearch to count log.levels

COUNT=$(curl -s -u $ELASTIC_USER:$ELASTIC_PASSWORD -X POST "$ES_HOST/$INDEX_PATTERN/_search" -H "Content-Type: application/json" -d '{
  "size": 0,
  "query": {
    "bool": {
      "must": [
        {
          "range": {
            "@timestamp": {
              "gte": "'"$query_time"'",
              "lte": "now"
            }
          }
        },
        {
          "term": {
            "service.name.keyword": "'"$SERVICE_NAMES"'"
          }
        }
      ]
    }
  },
  "aggs": {
    "log_levels": {
      "terms": {
        "field": "log.level.keyword",
        "size": 1000,
        "order": { "_key": "asc" }
      }
    }
  }
}')

# Extract the count for INFO level
COUNT_RESULT_INFO=$(echo $COUNT | jq -r '.aggregations.log_levels.buckets[] | select(.key == "INFO") | .doc_count')

LAST_STATE=1
if [ -f "$STATE_FILE" ]; then
  LAST_STATE=$(cat "$STATE_FILE")
fi

DATA_VIEW_ID=$(curl -s -u $ELASTIC_USER:$ELASTIC_PASSWORD "$KIBANA_HOST/api/saved_objects/_find?type=index-pattern" \
  | jq -r '.saved_objects[] | select(.attributes.title == "'"$INDEX_PATTERN"'") | .id')


TO_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
FROM_TIME=$(date -u -d "-30 minutes" +"%Y-%m-%dT%H:%M:%S.000Z")


# KIBANA_DISCOVER_URL="http://xx.xx.xx.xx:5601/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:now-30m,to:now))&_a=(columns:!(),dataSource:(dataViewId:'$DATA_VIEW_ID',type:dataView),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,field:log.level,index:'$DATA_VIEW_ID',key:log.level,negate:!f,params:(query:INFO),type:phrase),query:(match_phrase:(log.level:INFO)))),hideChart:!f,interval:auto,query:(language:kuery,query:''),sort:!(!('@timestamp',desc)),viewMode:documents)"

KIBANA_DISCOVER_URL="http://xx.xx.xx.xx:5601/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:'$FROM_TIME',to:'$TO_TIME'))&_a=(columns:!(),dataSource:(dataViewId:'$DATA_VIEW_ID',type:dataView),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,field:log.level,index:'$DATA_VIEW_ID',key:log.level,negate:!f,params:(query:INFO),type:phrase),query:(match_phrase:(log.level:INFO)))),hideChart:!f,interval:auto,query:(language:kuery,query:''),sort:!(!('@timestamp',desc)),viewMode:documents)"


# Check if the count is empty or not and send Discord message
if [ -z "$COUNT_RESULT_INFO" ]; then

  if [ "$LAST_STATE" -eq 1 ]; then
    MESSAGE="[Resolved] [${SERVICE_NAMES}] No INFO logs found in the last ${query_time}."

    curl -X POST "https://discord.com/api/v10/channels/$DISCORD_CHANNEL_ID/messages" \
      -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"content\": \"\`\`\`\n$MESSAGE\n\`\`\`\"}"
  fi
  echo 0 > "$STATE_FILE"
else

  MESSAGE="[Warning] [${SERVICE_NAMES}] INFO logs count in the last ${query_time}: $COUNT_RESULT_INFO"
  curl -X POST "https://discord.com/api/v10/channels/$DISCORD_CHANNEL_ID/messages" \
    -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"\`\`\`\n$MESSAGE\n\`\`\`\n**View in Kibana:**\n$KIBANA_DISCOVER_URL\"}"
  echo 1 > "$STATE_FILE"
fi