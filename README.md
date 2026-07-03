# Centralized Logging & Monitoring System

## Introduction

This project implements a centralized logging and monitoring stack for a demo application using Filebeat → Kafka → Logstash → Elasticsearch → Kibana, with Nagios Core providing host and service health monitoring. All components run in Docker on localhost, demonstrating how to collect, transport, process, visualize, and monitor logs in a way that can scale to production.

---
## Table of Contents

1. Project Overview
2. Architecture
3. Tools & Services
4. Kibana Dashboards & Visualizations
5. Features & Key Notes
6. Future Improvements

---

## Project Overview

The goal of this project is to build a fully containerized centralized logging stack for a sample application that writes structured logs to a file. Logs are shipped with Filebeat, sent through Kafka as an event bus, processed by Logstash, stored in Elasticsearch, and explored in Kibana Discover views and saved searches.

On top of that, Nagios Core monitors the Docker host and key HTTP endpoints (Kibana and Elasticsearch) to validate that the infrastructure behind the logging pipeline is reachable and healthy.

The main objectives are:
* Collect application logs from a Dockerized app in a consistent, structured format.
* Use Kafka as a reliable transport layer between log shippers and log processors.
* Parse, enrich, and index logs into Elasticsearch for fast querying.
* Build Kibana searches/visualizations to analyze INFO/WARNING/ERROR events.
* Use Nagios to monitor host and service availability for the same environment.

---

## Architecture

* `app.py` – Demo application that generates synthetic log lines (`INFO`, `WARNING`, `ERROR`) and writes them to `/logs/app.log` inside the container.
* `filebeat.yml` – Configures Filebeat to tail `/logs/app.log`, add ECS metadata, and publish events to the Kafka topic `app-logs`.
* `logstash.conf` – Consumes from Kafka (`app-logs`), parses each log message into fields like `level` and `msg`, normalizes timestamps, and outputs to Elasticsearch indices `logs-YYYY.MM.DD`.
* `docker-compose.yml` – Orchestrates all services (app, Filebeat, Kafka, Logstash, Elasticsearch, Kibana) plus supporting containers on a local Docker network and exposes ports such as `9200` (Elasticsearch), `5601` (Kibana), and `9092` (Kafka).
* `app.log` – Example log file showing the raw log lines that the app generates and Filebeat ships (useful for quick local testing and troubleshooting).

---

## Tools & Services

* Docker / Docker Compose – Container orchestration for the full stack.
* Demo App (Python) – Writes synthetic `INFO`, `WARNING`, and `ERROR` messages to `/logs/app.log`.
* Filebeat 8.x – Lightweight shipper that tails the log file and sends JSON events to Kafka using ECS-compatible fields.
* Apache Kafka – Distributed log/event bus decoupling log producers (Filebeat) from consumers (Logstash).
* Logstash – Ingests from Kafka, parses messages with filters, and sends documents to Elasticsearch.
* Elasticsearch 8.x – Stores and indexes log documents into date-based `logs-*` indices.
* Kibana 8.x – UI for ad‑hoc search, dashboards, and visualizations over the `logs-*` data.
* Nagios Core 4.x – Monitors the Docker host and HTTP endpoints (Elasticsearch/Kibana) for availability and basic health.

Kibana Dashboards & Visualizations

Kibana is used primarily through Discover and saved searches:
Error‑focused Discover view

The saved search `demo-app-errors` filters on:

level: "ERROR"

---

## Features & Keynotes

* End‑to‑end centralized logging pipeline
  - Logs collected from a containerized application and shipped via Filebeat.
  - Kafka used as a decoupling layer between producers and consumers.
* Structured, queryable logs
  - Logs enriched with ECS fields: @timestamp, service, environment, host.name, agent.*, etc.
  - Custom fields extracted: level (INFO/WARNING/ERROR) and msg (log message text).
* Kafka verification
  - Used docker exec and kafka-console-consumer inside the Kafka container to read raw events from the app-logs topic.
  - Observed continuous stream of JSON messages matching the app log patterns and offsets.
* Elasticsearch indexing
  - Documents stored in indices with correctly parsed fields and timestamps.
* Kibana analytics
  - Data view logs-* with @timestamp as the time field
  - Saved search demo-app-errors filtering on level: "ERROR"
  - Dashboard centralized-logging-dashboard embedding the saved search for quick error monitoring.

---

## ELK Stack Visuals and Trends

![Host State Trends](images/hst_state_trends.png)
![Host Status](images/hst_status.png)
![Host Status Details](images/hst_status_dtl.png)
![Server State Trends](images/serv_state_trends.png)
![Server Status](images/serv_status.png)
![Kibana Visual 1](images/kib_1.png)
![Kibana Visual 2](images/kib_2.png)

---

## Future Improvements

* Add Kibana dashboards (bar charts by log level, pie charts by service, etc.)
* Configure Kibana alerts for high error rates or repeated database failures.
* Extend Logstash parsing to extract additional fields (e.g., user_id, latency).
* Secure the stack with TLS and role‑based access control for non‑local use.
* Deploy to Kubernetes, Docker Swarm, or Elastic Cloud for higher availability and scale.
* Integrate Nagios notifications (email/Slack) for critical outages and correlate them with Kibana error spikes.
