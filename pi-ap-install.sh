#This turns a Raspberry Pi 3 into a wifi access point.
#Simply run this program from anywhere on the Raspberry Pi.
#By default, the ID is "Pi3-AP", password "raspberry", and the wifi network has a static IP address 172.24.1.1.
#Source: https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/

sudo apt-get install dnsmasq hostapd

if [ -e /etc/dhcpcd.conf ]
then
	cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
fi

sudo echo "hostname
clientid
persistent
option rapid_commit
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
option ntp_servers
require dhcp_server_identifier
slaac private
nohook lookup-hostname
interface wlan0  
    static ip_address=172.24.1.1/24
" > /etc/dhcpcd.conf

if [ -e /etc/network/interfaces ]
then
	cp /etc/network/interfaces /etc/network/interfaces.orig
fi

sudo echo "auto lo
iface lo inet loopback

iface eth0 inet dhcp

allow-hotplug wlan0  
iface wlan0 inet manual  
#    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
" > /etc/network/interfaces

sudo service dhcpcd restart

sudo echo "# This is the name of the WiFi interface we configured above
interface=wlan0

# Use the nl80211 driver with the brcmfmac driver
driver=nl80211

# This is the name of the network
ssid=Pi3-AP

# Use the 2.4GHz band
hw_mode=g

# Use channel 1
channel=1

# Accept all MAC addresses
macaddr_acl=0

# Use WPA authentication
auth_algs=1

# Require clients to know the network name
ignore_broadcast_ssid=0

# Use WPA2
wpa=2

# Use a pre-shared key
wpa_key_mgmt=WPA-PSK

# The network passphrase
wpa_passphrase=raspberry

# Use AES, instead of TKIP
rsn_pairwise=CCMP
" > /etc/hostapd/hostapd.conf

sudo sed -i -e 's/\#DAEMON_CONF=\"\"/ DAEMON_CONF=\"\/etc\/hostapd\/hostapd.conf\"/' /etc/default/hostapd

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig  
sudo echo "interface=wlan0      # Use interface wlan0  
bind-interfaces      # Bind to the interface to make sure we aren't sending things elsewhere  
server=8.8.8.8       # Forward DNS requests to Google DNS  
domain-needed        # Don't forward short names  
bogus-priv           # Never forward addresses in the non-routed address spaces.  
dhcp-range=172.24.1.50,172.24.1.150,12h # Assign IP addresses between 172.24.1.50 and 172.24.1.150 with a 12 hour lease time
" > /etc/dnsmasq.conf  

sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT  

sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

sudo echo "iptables-restore < /etc/iptables.ipv4.nat" > /lib/dhcpcd/dhcpcd-hooks/70-ipv4-nat

sudo service hostapd start  
sudo service dnsmasq start  
