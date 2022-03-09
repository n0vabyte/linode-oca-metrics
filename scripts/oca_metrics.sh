#!/bin/bash

infile=($(cat OCA_results.txt))
metrics_path='/etc/node_exporter.d'

function oca_metrics {
	count=0
	oca_count=${#infile[@]}

	while [ $count -lt $oca_count ]; do
		id=$(curl -s https://api.linode.com/v4/linode/stackscripts/${infile[count]}  | jq -r '.id')
		label=$(curl -s https://api.linode.com/v4/linode/stackscripts/${infile[count]}  | jq -r '.label')
		image=$(curl -s https://api.linode.com/v4/linode/stackscripts/${infile[count]}  | jq -r '.images[0]')
		deployment_total=$(curl -s https://api.linode.com/v4/linode/stackscripts/${infile[count]}  | jq -r '.deployments_total')
		deployment_active=$(curl -s https://api.linode.com/v4/linode/stackscripts/${infile[count]}  | jq -r '.deployments_active')

		cat << EOF > $metrics_path/${infile[count]}.$$
# HELP deployment_total total deployment
# TYPE deployment_total gauge
deployment_total{label="${label}",image="${image}",id="${id}"} $deployment_total

# HELP deployment_active active deployments
# TYPE deployment_active gauge
deployment_active{label="${label}",image="${image}",id="${id}"} $deployment_active
EOF
	mv $metrics_path/${infile[count]}.$$ $metrics_path/${infile[count]}.prom
	count=$(($count + 1))
	done
}

function main {
	oca_metrics
}
main
