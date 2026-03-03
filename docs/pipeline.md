# 📡 Streaming Data Pipeline

## Use Case: Network Device Monitoring

Simulated router telemetry metrics:

- CPU usage
- Memory usage
- Interface errors
- Packets in/out
- Timestamp
- Device ID

---

## 1️⃣ Producer

Python client:

- Reads synthetic dataset
- Sends JSON messages to Kafka
- Topic: `router.metrics.raw`
- Can simulate real-time streaming

Example message:

```json
{
  "device_id": "router-042",
  "timestamp": "2026-03-01T22:15:00Z",
  "cpu_usage": 54.3,
  "memory_usage": 71.2,
  "interface_errors": 3,
  "packets_in": 123456,
  "packets_out": 122998
}