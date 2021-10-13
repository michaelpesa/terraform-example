output "newrelic_dashboard_url" {
  description = "NewRelic dashboard URL"
  value       = newrelic_one_dashboard.dashboard.permalink
}
