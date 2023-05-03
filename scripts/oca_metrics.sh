#!/bin/bash

outfile='OCA_results.txt'
function oca_ssid {
        local paging=($(curl -s "https://api.linode.com/v4/linode/stackscripts/?page=1" | jq -r '.page, .pages'))
        local current_page=${paging[0]} # eq 1
        local total_pages=${paging[1]} # eq 18

        while [[ $current_page -le $total_pages ]]; do
                local ss_url=$(curl -s "https://api.linode.com/v4/linode/stackscripts/?page=$current_page")
                local reindex_results=$(echo $ss_url | jq '.data[].id' | wc -l)
                local ss_count=$(expr $reindex_results - 1)
                local page_counter=0

                while [[ $page_counter -le $ss_count ]]; do
                        local ss_data=($(echo $ss_url | jq -r ".data[$page_counter].username, .data[$page_counter].label"))
                        local username=${ss_data[0]}
                        local label=${ss_data[@]:1}
                        if [ "$username" == "linode" ] && [[ "$label" == *"One-Click"* ]]; then
                                echo $ss_url | jq -r ".data[$page_counter].id"
                        fi
                local page_counter=$(( $page_counter + 1 ))
                done
        local current_page=$(( $current_page + 1 ))
        done
}

function get_metrics {
        if [ ! -f $outfile ]; then
                echo "[WARN] file $outfile not found. Pulling OCA IDs before continuing"
                main pull_oca
        fi             

        local infile=($(cat OCA_results.txt))
        local metrics_path='/etc/node_exporter.d'
        local count=0
        local oca_count=${#infile[@]}

        while [ $count -lt $oca_count ]; do
                local ss_data="$(curl -s  https://cloud.linode.com/api/v4/linode/stackscripts/${infile[count]} | jq -r '.id, .label, .images[0], .deployments_total, .deployments_active')"
                local id=$(echo "${ss_data}" | sed -n '1 p')
                local label=$(echo "${ss_data}" | sed -n '2 p')
                local image=$(echo "${ss_data}" | sed -n '3 p')
                local deployment_total=$(echo "${ss_data}" | sed -n '4 p')
                local deployment_active=$(echo "${ss_data}" | sed -n '5 p')
                local is_cluster=$(
                if [[ -z $(echo "${ss_data}" | sed -n '2 p' | grep "Cluster One-Click\|Cluster Null One-Click") ]]; then
                        echo "no"
                else
                        echo "yes"
                fi
                )

                cat << EOF > $metrics_path/${infile[count]}.$$
# HELP deployment_total total deployment
# TYPE deployment_total gauge
deployment_total{label="${label}",image="${image}",id="${id}",cluster="${is_cluster}"} $deployment_total

# HELP deployment_active active deployments
# TYPE deployment_active gauge
deployment_active{label="${label}",image="${image}",id="${id}",cluster="${is_cluster}"} $deployment_active
EOF
        mv $metrics_path/${infile[count]}.$$ $metrics_path/${infile[count]}.prom
        local count=$(($count + 1))
        done
}

function usage {
   cat << EOF
Usage: $0 [pull_oca|get_metrics]
Custom textfile script to scrape OCA metrics 

   - pull_oca           pulls all OCA IDs from API endpoint and writes to $outfile
   - get_metrics        pulls stats for individual OCA that were written to $outfile

Examples:
   $0 pull_oca
   $0 get_metrics
EOF
}

function api_check {
        # Internal errors are shown as 502s
        local log_file="api_error.log"
        local api_status=$(curl -s -o /dev/null -Iw "%{http_code}" "https://api.linode.com/v4/linode/stackscripts/")
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
        local arg=$1
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
