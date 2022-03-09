# Linode OCA Monitoring Dashboard
Montior Linode's one-click marketplace applications with Prometheus and Grafana. This small project was created to provide high-level insight on OCA deployment.


# How it works

We are going to be using Prometheus and Grafana as an observatory platform to display the metrics that we are scrapting from Linode's stackscript endpoint. Before getting this working you will need server with Prometheus, Grafana and Node Exporter. 

Node Exporter is started using the textfile collector which allows it to collect statistical data from `/etc/node_exporter.d`. The data collected in this directory is then scraped by Prometheus. We use 2 scripts to put scrape all of the data that we need before it's put in `/etc/node_exporter.d`:

- scripts/refresh_oca.sh
- scripts/oca_metrics.sh

refresh_oca.sh iterates through every page in the `api.linode.com/v4/linode/stackscripts` and grabs the associated  OCAS stackscript IDs and writes out to a file. The oca_metrics.sh iterates through the file that was written and parses for particular elements of the OCA which will be used in the dashboard.

The refresh of the OCAs occur routinely at midnight via cron job while the actual metrics of the OCAs are scraped every minute.


The flow of operation can be observed below - 
![](/images/overview.png)

# Setup

YOU ARE HREE. INSTRUCTIONS ON CRON, SCRIPTS, NODE_EXPORTER TEXFILE COLLECTOR

# Requirements

- Latest version of [Prometheus](https://prometheus.io/docs/prometheus/latest/installation/)
- Latest version of [Grafana]https://grafana.com/docs/grafana/latest/installation/debian/)

# Install Dashboard

The installation is pretty straight forward and all you have to do is import the json value for the dashboard. 

1. In Grafana's backend, on the left-hand pane, hover over the `+` sign and click on `import`

![](/images/step1.png)


2. Next, you have the option to paste the dashboard's json values or simply upload the dashboard if you have it on your local computer.  When ready, hit the `Load` button.

![](/images/step2.png)

3. Hit the `Import` button.

Pretty simple and straightforward - You're done!

![](/images/dashboard_preview.png)