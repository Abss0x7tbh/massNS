#$1 - domain whose auth NS is to be found out
#$2 - Target domain list. subdomains of the Target

mkdir /root/massNS/
mkdir /root/massNS/$1/
touch ~/massNS/$1/$1_ns_ip.txt
touch ~/massNS/$1/$1_ns.txt
touch ~/massNS/$1/$1_op.txt
touch ~/massNS/$1/$1_op_success.txt

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


}

getActive () {

#run masscan
masscan -iL ~/massNS/$1/$1_ns_cidr.txt -p 53 --rate=1000 | awk '{print $(NF)}' > ~/massNS/$1/$1_resolvers.txt

}

resolvers () {

while IFS= read -r line
do
	#select random input from nameservers file
	random_ns=$(shuf -n 1 ~/massNS/$1/$1_resolvers.txt |xargs ) 
	
	echo $random_ns >> ~/massNS/$1/$1_resolvers_used.txt

done<$2

}

resolve () {

interlace -pL ~/massNS/$1/$1_resolvers_used.txt -tL $2 -o ~/massNS/$1/$1_op.txt -threads 5 -c "nslookup _target_  _proxy_ >> _output_" -v

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
echo "Total Number of Resolvers : `wc -l ~/massNS/$1/$1_resolvers.txt`"
echo "Randomly Picking resolvers to be used with the target list at $2"
resolvers $1 $2
echo "----"
echo "Resolving target list using Interlace"
echo "------------------------------"
resolve $1 $2
echo "All done. Output file at ~/massNS/$1/$1_op_success.txt"
echo "------------------------------"
echo "Successfully resolved the following domains "
echo "-------------------------------------"
cat ~/massNS/$1/$1_op.txt | grep -E "^(Name|Address)" > ~/massNS/$1/$1_tmp.txt
grep -v -f ~/massNS/$1/$1_resolvers_used.txt ~/massNS/$1/$1_tmp.txt > ~/massNS/$1/$1_op_success.txt
cat ~/massNS/$1/$1_op_success.txt
#dig could also be used only for ips
#only ips
echo "Resolved list of IP addresses can be found at ~/massNS/$1/$1_op_success_ip.txt. Opening now "
echo "-----------------------------------"
cat ~/massNS/$1/$1_op_success.txt | grep -E "Address" | awk '{print $2}' > ~/massNS/$1/$1_op_success_ip.txt
cat ~/massNS/$1/$1_op_success_ip.txt
echo "-------------------------------"

