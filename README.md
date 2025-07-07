# I. Reference build ELK stack with Docker
https://github.com/Einsteinish/Einsteinish-ELK-Stack-with-docker-compose/tree/master

# II. Query ES get field `log.level` & `service.name`
### Query ES lấy field `log.level` và `service.name` trong index pattern `vector-tubt-*` theo time range `now-30s` -> `now`, sort theo `@timestamp`

```sh
curl -s -u $ELASTIC_USER:$ELASTIC_PASSWORD -X POST "http://localhost:9200/vector-tubt-*/_search" -H "Content-Type: application/json" -d '{
  "_source": ["log.level", "service.name"],
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-30s",
        "lte": "now"
      }
    }
  },
  "sort": [
    { "@timestamp": { "order": "asc" } }
  ],
  "size": 500
}'
```

> Sample Output: 

```sh
{
  "took": 2,
  "timed_out": false,
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": {
      "value": 3,
      "relation": "eq"
    },
    "max_score": null,
    "hits": [
      {
        "_index": "vector-tubt-2025-07-04",
        "_id": "CC4b1JcBRpiYDSUfB7TI",
        "_score": null,
        "_source": {
          "log.level": "INFO",
          "service.name": "ES_ECS"
        },
        "sort": [
          1751610229520
        ]
      },
      {
        "_index": "vector-tubt-2025-07-04",
        "_id": "JC4b1JcBRpiYDSUfMLRQ",
        "_score": null,
        "_source": {
          "log.level": "INFO",
          "service.name": "ES_ECS"
        },
        "sort": [
          1751610239900
        ]
      },
      {
        "_index": "vector-tubt-2025-07-04",
        "_id": "QC4b1JcBRpiYDSUfWLTa",
        "_score": null,
        "_source": {
          "log.level": "INFO",
          "service.name": "ES_ECS"
        },
        "sort": [
          1751610250275
        ]
      }
    ]
  }
}
```

# III. Count số lượng `log.level` = INFO để alert (Vì tài liệu lab nên dùng log INFO để alert)

**Option 1:** Query ES lấy field `log.level`, Dùng `jq` để select trường `["log.level"] == "INFO"` và `["service.name"] == "ES_ECS"` trong respone JSON sau đó dùng `world count (wc)` để đếm tất cả các dòng thỏa mãn 2 điều kiện trên

```sh
curl -s -u $ELASTIC_USER:$ELASTIC_PASSWORD -X POST "http://localhost:9200/vector-tubt-*/_search" -H "Content-Type: application/json" -d '{
  "_source": ["log.level", "service.name"],
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-1m",
        "lte": "now"
      }
    }
  },
  "sort": [
    { "@timestamp": { "order": "asc" } }
  ],
  "size": 500
}' | jq -c '.hits.hits[]._source | select(.["log.level"] == "INFO" and .["service.name"] == "ES_ECS")' | wc -l
```

**Option 2:** Query ES filter service `ES_ECS` dùng `Aggregation (aggs)` group by theo field `log.level.keyword` để lấy all `log.level`. Sau đó select trường `key == "INFO"` và lấy `doc_count`

```sh
curl -s -u $ELASTIC_USER:$ELASTIC_PASSWORD -X POST "http://localhost:9200/vector-tubt-*/_search" -H "Content-Type: application/json" -d '{
  "size": 0,
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-1m",
        "lte": "now"
      }
    }
  },
  "aggs": {
    "log_levels": {
      "terms": {
        "field": "log.level.keyword",
        "size": 1000
      }
    }
  }
}' | jq -r '.aggregations.log_levels.buckets[] | select(.key == "INFO") | .doc_count'
```

# IV. Script Alert

[getLogLevel.sh](./alerts/scripts/getLogLevel.sh)