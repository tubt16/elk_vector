# Filter Alias 

## Traces index
POST /_aliases?pretty
{
  "actions": [
    {
      "add": {
        "index": "traces-apm*",
        "alias": "team1-traces-apm",
        "filter": {
          "prefix": {
            "service.name": {
              "value": "team1-"
            }
          }
        }
      }
    }
  ]
}

POST /_aliases?pretty
{
  "actions": [
    {
      "add": {
        "index": "traces-apm*",
        "alias": "team2-traces-apm",
        "filter": {
          "prefix": {
            "service.name": {
              "value": "team2-"
            }
          }
        }
      }
    }
  ]
}

## Logs index

POST /_aliases?pretty
{
  "actions": [
    {
      "add": {
        "index": "logs-apm*",
        "alias": "team1-logs-apm",
        "filter": {
          "prefix": {
            "service.name": {
              "value": "team1-"
            }
          }
        }
      }
    }
  ]
}

POST /_aliases?pretty
{
  "actions": [
    {
      "add": {
        "index": "logs-apm*",
        "alias": "team2-logs-apm",
        "filter": {
          "prefix": {
            "service.name": {
              "value": "team2-"
            }
          }
        }
      }
    }
  ]
}

## Metrics index

POST /_aliases?pretty
{
  "actions": [
    {
      "add": {
        "index": "metrics-apm*",
        "alias": "team1-metrics-apm",
        "filter": {
          "prefix": {
            "service.name": {
              "value": "team1-"
            }
          }
        }
      }
    }
  ]
}

POST /_aliases?pretty
{
  "actions": [
    {
      "add": {
        "index": "metrics-apm*",
        "alias": "team2-metrics-apm",
        "filter": {
          "prefix": {
            "service.name": {
              "value": "team2-"
            }
          }
        }
      }
    }
  ]
}

## Get ALL Alias
GET /_alias?pretty