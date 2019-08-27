#$1 - domain whose auth NS is to be found out
#$2 - Target domain list. subdomains of the Target

#mkdir /root/massNS/
mkdir /root/massNS/$1/
touch ~/massNS/$1/$1_ns_ip.txt
touch ~/massNS/$1/$1_ns.txt
touch ~/massNS/$1/$1_op.txt
touch ~/massNS/$1/$1_op_cname.txt
touch ~/massNS/$1/$1_ns_cidr.txt

getNS () {
host -t ns $1 | awk '{ print $(NF) }' | sed 's/\.$//' > ~/massNS/$1/$1_ns.txt
toIP $1
}

toIP () {

while IFS= read -r line
do
	host -t A $line | awk '{print $(NF)}' >> ~/massNS/$1/$1_ns_ip.txt
done<~/massNS/$1/$1_ns.txt

}

toCIDR () {

while IFS= read -r line
do
	ipcalc $line | awk '{print $2}' | grep / >> ~/massNS/$1/$1_ns_cidr.txt
done<~/massNS/$1/$1_ns_ip.txt

# filter awsdns ipranges

sed -i '/^205/d' ~/massNS/$1/$1_ns_cidr.txt

}

getActive () {

#run masscan
masscan -iL ~/massNS/$1/$1_ns_cidr.txt -p 53 --rate=1000 | awk '{print $(NF)}' > ~/massNS/$1/$1_resolvers.txt

}


resolve () {

#interlace -pL ~/massNS/$1/$1_resolvers_used.txt -tL $2 -o ~/massNS/$1/$1_op.txt -threads 5 -c "nslookup _target_  _proxy_ >> _output_" -v
massdns -r ~/massNS/$1/$1_resolvers.txt -o J -t A -q --flush $2 | jq -r '.'  > ~/massNS/$1/$1_op.txt

}

echo "Starting..."
echo "----------------------------"
echo "Fetching the authoritative nameservers of $1"
echo "---"
getNS $1
echo "The Authoritative nameservers of $1 are :"
cat ~/massNS/$1/$1_ns_ip.txt
echo "----------------------------"
echo "Fetching CIDR of the different Nameserver providers involved"
echo "----------------------------"
toCIDR $1
echo "The CIDR's involved are"
cat ~/massNS/$1/$1_ns_cidr.txt
echo "----------------------------"
echo "Probing for active DNS servers in the listed CIDR / IP Range"
getActive $1
echo "----"
echo "Active resolvers are :"
echo "----------------------------"
cat ~/massNS/$1/$1_resolvers.txt
echo "-----------------------------"
#echo "Total Number of Resolvers : `wc -l ~/massNS/$1/$1_resolvers.txt`"
#echo "Randomly Picking resolvers to be used with the target list at $2"
#resolvers $1 $2
echo "----"
echo "Resolving target list using massdns"
echo "------------------------------"
resolve $1 $2
echo "All done! "
echo "------------------------------"
echo "Results :  "
echo "-------------------------------------"
#cat ~/massNS/$1/$1_op.txt | grep -E "^(Name|Address)" > ~/massNS/$1/$1_tmp.txt
#grep -v -f ~/massNS/$1/$1_resolvers_used.txt ~/massNS/$1/$1_tmp.txt > ~/massNS/$1/$1_op_success.txt
#column -x ~/massNS/$1/$1_op_success.txt
#make a file for canonical name entires
#cat ~/massNS/$1/$1_op.txt | grep canonical > ~/massNS/$1/$1_op_cname.txt
#dig could also be used only for ips
#only ips
cat ~/massNS/$1/$1_op.txt | jq
echo "---------------------------------"

#only ip
cat ~/massNS/$1/$1_op.txt | jq -r 'if .resp_type =="A" then .data else empty end' > ~/massNS/$1/$1_op_ip.txt
cat ~/massNS/$1/$1_op.txt | jq -r 'if .resp_type =="CNAME" then .data else empty end' > ~/massNS/$1/$1_op_cname.txt
echo "The resolved  IP addresses are : "
echo "-----------------------------------"
#cat ~/massNS/$1/$1_op_success.txt | grep -E "Address" | awk '{print $2}' > ~/massNS/$1/$1_op_success_ip.txt
cat ~/massNS/$1/$1_op_ip.txt
echo "-------------------------------"
echo "Stats"
echo "-------------------------------"
echo "[*] Resolvers obtained and used : `cat ~/massNS/$1/$1_resolvers.txt | wc -l`"
echo "[*] Target List had `cat $2 | wc -l`  domains"
echo "[*] A records obtained for `cat ~/massNS/$1/$1_op_ip.txt | wc -l`  domains"
echo "[*] CNAME records obtained for `cat ~/massNS/$1/$1_op_cname.txt | wc -l` domains"
echo "--------------------------------"
echo "Output Files :"
echo "--------------------------------"
echo "[*] Resolved IP Addresses : ~/massNS/$1/$1_op_ip.txt"
echo "[*] Generic JSON format output :  ~/massNS/$1/$1_op.txt"
echo "[*] DNS Provider CIDR range that were probed :  ~/massNS/$1/$1_ns_cidr.txt"
echo "---------------------------------"

