terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 2.21.0"
    }
  }
}

data "newrelic_entity" "app_name" {
  name   = "${var.app_name}_${var.env_name}"
  type   = "APPLICATION"
  domain = "APM"
}

resource "newrelic_alert_policy" "transaction_duration" {
  name = "Transaction Duration Alert Policy"
}

resource "newrelic_nrql_alert_condition" "foo" {
  policy_id                    = newrelic_alert_policy.transaction_duration.id
  type                         = "static"
  name                         = "Transaction Duration Alert Condition"
  description                  = "Alert when transactions are taking too long"
  runbook_url                  = "https://www.example.com"
  enabled                      = true
  value_function               = "single_value"
  violation_time_limit_seconds = 3600

  nrql {
    query             = "SELECT average(duration) FROM Transaction where appName = '${data.newrelic_entity.app_name.name}'"
    evaluation_offset = 3
  }

  critical {
    operator              = "above"
    threshold             = 5.5
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_one_dashboard" "dashboard" {
  name = "${data.newrelic_entity.app_name.name} Dashboard"

  page {
    name = "Overview"

    widget_billboard {
      title  = "Requests per minute"
      row    = 1
      column = 1

      nrql_query {
        query = "FROM Transaction SELECT rate(count(*), 1 minute)"
      }
    }

    widget_bar {
      title  = "Average transaction duration, by application"
      row    = 1
      column = 5

      nrql_query {
        query = "FROM Transaction SELECT average(duration) FACET appName"
      }
    }
  }
}