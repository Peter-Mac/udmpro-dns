# UDM-PRO DNS Updates
## The Problem
My home lab Ubiquiti Dream Machine UDM Pro server is allocated a random DNS by my ISP on an ad-hoc basis and as a result any services I run behind the UDMPRO that require public access are prone to have their DNS entries get out of whack.

I have recently moved from GoDaddy DNS to Cloudflare (as GoDaddy pulled access to their APIs for all but their big customers - **rant!**).

I use Cloudflare's proxy service to hide my public IP and act as  a potential choking point for inbound traffic. 

## The Solution
This set of script verifies the current external ip address of the UDM Pro unit against the previously identified value and if the address has changed since last run, makes a callout to an update dns script (update-cloudflare-dns.sh).

The script relies on a configuratin file (check-ip.conf) for preferences.
A cron job containing schedule/frequency is used to control execution with a high frequency preferred to ensure any outages (change of Ip and internal service breaks) are identified quickly.

An alternate approach is to run the update-dns scripts more frequently but that would create a network / bandwidth cost for the continuous updating of dns entries that don't need to be changed. This approach is a happy medium (check ip change and only perform a dns update when an actual change has been identified.

Notifications also sent via telegram to my home lab bot. The configuration settings for both the check-ip and the update-cloudflare-dns are in theor respective configuration files.
