{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'loki_alerts',
        rules: [
          {
            alert: 'LokiRequestErrors',
            expr: |||
              100 * sum(rate(loki_request_duration_seconds_count{status_code=~"5.."}[2m])) by (%(group_by_cluster)s, job, route)
                /
              sum(rate(loki_request_duration_seconds_count[2m])) by (%(group_by_cluster)s, job, route)
                > 10
            ||| % $._config,
            'for': '15m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: |||
                {{ $labels.job }} {{ $labels.route }} is experiencing {{ printf "%.2f" $value }}% errors.
              |||,
            },
          },
          {
            alert: 'LokiRequestPanics',
            expr: |||
              sum(increase(loki_panic_total[10m])) by (%(group_by_cluster)s, job) > 0
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: |||
                {{ $labels.job }} is experiencing {{ printf "%.2f" $value }}% increase of panics.
              |||,
            },
          },
          {
            alert: 'LokiRequestLatency',
            expr: |||
              %(per_cluster_label)s_namespace_job_route:loki_request_duration_seconds:99quantile{route!~"(?i).*tail.*|/schedulerpb.SchedulerForQuerier/QuerierLoop"} > 1
            ||| % $._config,
            'for': '15m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: |||
                {{ $labels.job }} {{ $labels.route }} is experiencing {{ printf "%.2f" $value }}s 99th percentile latency.
              |||,
            },
          },
          {
            alert: 'LokiTooManyCompactorsRunning',
            expr: |||
              sum(loki_boltdb_shipper_compactor_running) by (%(group_by_cluster)s) > 1
            ||| % $._config,
            'for': '5m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: |||
                {{ $labels.cluster }} {{ $labels.namespace }} has had {{ printf "%.0f" $value }} compactors running for more than 5m. Only one compactor should run at a time.
              |||,
            },
          },
        ],
      },
    ],
  },
}
