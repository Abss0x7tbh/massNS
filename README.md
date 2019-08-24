
# massNS
A tool that turns the authoritative nameservers of DNS providers to resolvers and resolves the target domain list. As of now the tool only resolves the A record for the list of domains.


# Basic Idea

The idea behind this tool is a product of observing how an authoritative nameserver of `TARGET1` would also resolve `TARGET2` provided both belonged to the same DNS Provider. So using this we could for a `TARGET` collect a huge bunch of authoritative nameservers and use them as resolvers instead of using the public dns resolvers.

**Proof**

1. Fetch `bugcrowd.com` nameservers 

```
$ host -t ns bugcrowd.com
bugcrowd.com name server edna.ns.cloudflare.com.
bugcrowd.com name server lee.ns.cloudflare.com.
```
2. Fetch `upserve.com` nameservers 

```
$ host -t ns upserve.com
upserve.com name server ulla.ns.cloudflare.com.
upserve.com name server jay.ns.cloudflare.com.
```
3. Resolve `bugcrowd.com` using upserve's nameserver `jay.ns.cloudflare.com`

```
$ nslookup bugcrowd.com jay.ns.cloudflare.com
Server:		jay.ns.cloudflare.com
Address:	173.245.59.123#53

Name:	bugcrowd.com
Address: 104.20.5.239
Name:	bugcrowd.com
Address: 104.20.4.239
Name:	bugcrowd.com
Address: 2606:4700:10::6814:5ef
Name:	bugcrowd.com
Address: 2606:4700:10::6814:4ef
```
4. Resolve `docs.bugcrowd.com` using upserve's nameserver `jay.ns.cloudflare.com`

```
$ nslookup docs.bugcrowd.com jay.ns.cloudflare.com
Server:		jay.ns.cloudflare.com
Address:	173.245.59.123#53

Name:	docs.bugcrowd.com
Address: 104.20.5.239
Name:	docs.bugcrowd.com
Address: 104.20.4.239
Name:	docs.bugcrowd.com
Address: 2606:4700:10::6814:5ef
Name:	docs.bugcrowd.com
Address: 2606:4700:10::6814:4ef
```
5. Repeating the same for `upserve.com` . Resolving `upserve.com` using bugcrowd's nameserver `edna.ns.cloudflare.com`

```
$ nslookup upserve.com edna.ns.cloudflare.com
Server:		edna.ns.cloudflare.com
Address:	173.245.58.109#53

Name:	upserve.com
Address: 35.221.46.9
```

# Observation

As seen above how the *authoritative nameserver's aren't tied down to their specific domain names*, we could leverage the way these DNS providers are configured. We could probe into the IP range of the respective DNS Providers > grab all the active DNS servers in their range > use them as resolvers against our target list. All these servers would answer authoritatively due to their configuration as observed.

# Requirements 

- ipcalc

```
sudo apt-get install ipcalc
```
- [Interlace](https://github.com/codingo/Interlace) at the root . Interlace here is used to multi-thread `nslookup`.
- Masscan

# Tool Usage

- Run 

```
cd massNS
chmod +x massns.sh
./massns.sh target.com /path/to/taregt/domains
```

# Output

![domain's & ip's ](https://github.com/Abss0x7tbh/massNS/blob/master/ss_1.png)
![only ip's](https://github.com/Abss0x7tbh/massNS/blob/master/ss_2.png)
# Exceptions

`awsdns` seems to not allow this. Other DNS providers that allow this are :

- `*.ns.cloudflare.com` 
- `*.*.dynect.com/net` 
- `*.ultradns.net/org/biz/com`
and a lot more..

**P.S** : This is a product of pure observation. I'm still poking at things to understand them properly. Please do share what you think of this approach. Thanks!
