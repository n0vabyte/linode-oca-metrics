# Linode OCA Monitoring Dashboard
Montior Linode's one-click marketplace applications with Prometheus and Grafana. This small project was created to provide high-level insight on OCA deployment.


# How it works

We are going to be using Prometheus and Grafana as an observatory platform to display metrics that we are scrapting from Linode's stackscript endpoint. Before getting this working you will need a server with Prometheus, Grafana and Node Exporter. 

Node Exporter should be started using the textfile collector which allows it to collect statistical data from `/etc/node_exporter.d`. The data collected in this directory is read by node exporter and exposed to Prometheus. We use one script to scrape all of the data and place it in `/etc/node_exporter.d`. There are 2 functions responsible for everything

- pull_oca
- get_metrics

The pull_oca run a midnight which iterates through every page in the `api.linode.com/v4/linode/stackscripts` and grabs the associated OCAs stackscript IDs and writes out to a file. Every minute get_metrics iterates through the file that was written and parses for particular elements to be used in our dashboard.

The flow of operation can be observed below:
![](/images/overview.png)

# Requirements

- Latest version of [Prometheus](https://prometheus.io/docs/prometheus/latest/installation/)
- Latest version of [Grafana](https://grafana.com/docs/grafana/latest/installation/debian/)

# Setup

Before installing the OCA dashboard you will need to make sure that Node Exporter is started with the textfile collector. You can view the systemd service file in `systemd/node_exporter.service` for reference.

### Step 1 - Setup

First, you'll need to create the node_exporter.d directory and make the script executable:
```
mkdir /etc/node_exporter.d
cp linode-oca-metrics/script/oca_metrics.sh /root/
cd /root && chmod +x oca_metrics.sh
```

### Step 2 - Run it

Next, you can either setup the cron and forget about it. But for the sake of excercise, we'll run the script manually and then create the cron jobs:
```
cd /root
./oca_metrics.sh get_metrics
```

Running the script for the first time will take a while because the script needs to fetch all of the OCAs from the API endpoint. Might be wise to put this in a screen session because it can take 8 minutes.

### Step 3 - Cron It

The last thing we want to do to do is create the following cron jobs:

```
# Refresh OCA app at midnight
0 0 * * * /bin/bash /root/oca_metrics.sh pull_oca

# Get OCA metrics
* * * * * /bin/bash /root/oca_metrics.sh get_metrics
```

We fetch for new OCAs once everyday at midnight and get stats for the current ones we have every minute.

# Install Dashboard

The installation is pretty straight forward and all you have to do is import the json value for the dashboard. 

1. In Grafana's backend, on the left-hand pane, hover over the `+` sign and click on `import`

![](/images/step1.png)


2. Next, you have the option to paste the dashboard's json values or simply upload the dashboard if you have it on your local computer.  When ready, hit the `Load` button.

![](/images/step2.png)

3. On the next screen hit the `Import` button.

Pretty simple and straightforward - You're done!

![](/images/dashboard_preview1.png)

One thing you will notice is that the `OCA Trend` panel will not have any data because the `Min step` is set to 30 minutes. You will need to wait at least 24 hours to have at least 48 data points or remove the `Min step` by editing the panel.