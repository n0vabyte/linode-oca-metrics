#!/bin/bash

outfile='OCA_results.txt'
function oca_ssid {
        paging=($(curl -s "https://api.linode.com/v4/linode/stackscripts/?page=1" | jq -r '.page, .pages'))
        current_page=${paging[0]} # eq 1
        total_pages=${paging[1]} # eq 18

        while [[ $current_page -le $total_pages ]]; do
                ss_url=$(curl -s "https://api.linode.com/v4/linode/stackscripts/?page=$current_page")
                reindex_results=$(echo $ss_url | jq '.data[].id' | wc -l)
                ss_count=$(expr $reindex_results - 1)
                page_counter=0

                while [[ $page_counter -le $ss_count ]]; do
                        ss_data=($(echo $ss_url | jq -r ".data[$page_counter].username, .data[$page_counter].label"))
                        username=${ss_data[0]}
                        label=${ss_data[@]:1}
                        if [ "$username" == "linode" ] && [[ "$label" == *"One-Click"* ]]; then
                                echo $ss_url | jq -r ".data[$page_counter].id"
                        fi
              	page_counter=$(( $page_counter + 1 ))
                done
	current_page=$(( $current_page + 1 ))
        done
}

function get_metrics {
	if [ ! -f $outfile ]; then
		echo "[WARN] file $outfile not found. Pulling OCA IDs before continuing"
		main pull_oca
	fi

	infile=($(cat OCA_results.txt))
	metrics_path='/etc/node_exporter.d'
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

function usage {
   cat << EOF
Usage: $0 [pull_oca|get_metrics]
Custom textfile script to scrape OCA metrics

   - pull_oca		pulls all OCA IDs from API endpoint and writes to $outfile
   - get_metrics	pulls stats for individual OCAs that were written to $outfile

Examples:
   $0 pull_oca
   $0 get_metrics
EOF
}

function api_check {
        # Internal errors are shown as 502s
        log_file="api_error.log"
        api_status=$(curl -s -o /dev/null -Iw "%{http_code}" "https://api.linode.com/v4/linode/stackscripts/")
        if [ $api_status -eq 502 ]; then
                cat << EOF >> $log_file
============================================================
Date: $(date)

[CRIT] We've encountered an error reaching the API endpoint.
Exiting to avoid overwritting current metrics
==============================================================

EOF
        exit 1
        fi
}

function main {
	arg=$1
	case $arg in
		pull_oca)
		        echo "[INFO] Pulling OCAs...please wait"
		        oca_ssid 2>/dev/null > $outfile.$$
		        mv $outfile.$$ $outfile
		        echo "[INFO] Complete! Result written to $outfile";;
		get_metrics)
			get_metrics;;
		*)
			usage
	esac
}
api_check
main $1
