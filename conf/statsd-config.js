{
  graphiteHost: "127.0.0.1",
  graphitePort: 2003,
  port: 8125,
  flushInterval: 1000,
  backends: [ "./backends/graphite" ],
  deleteIdleStats: true,
  deleteGauges: true
}
