#!/bin/bash

######################################################
# Iterates throught the stackscript API endpoint     #
# and grabs the stackscript IDs associated with OCAs #
#####################################################

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

function main {
	echo "[+] Running...please wait"
	oca_ssid 2>/dev/null > $outfile.$$
	mv $outfile.$$ $outfile
	echo "[+] Complete! Result written to $outfile"
}
main
