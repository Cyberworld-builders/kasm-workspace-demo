# Azure Windows Server

> *A Kasm Workspace server installed on a Windows Server hosted in Azure Cloud.*

## General Requirements
The requirement is to add Kasm to a Windows server, technically on their onprem VMware ESXi virtual machine. I'm not as familiar with ESXi, so my plan is to test, document and possibly automate the setup in a familiar environment. That way I can reproduce it quickly on their infrastructure and know that anything that goes wrong is not related to my understanding of how to get Kasm working, but related to nuances in their infrastructure architecture or server configuration.

### Additional Benefits
Another benefit of this is that if I run out of time and I don't have a demo ready (God forbid) by next week, I can offer to present a demo on my own infrastructure. Having it automated makes it practical to tear down to save cost and fire up to have it available.

### Ideal Outcome
The best possible outcome is that I can get it working on my own Windows server and then quickly port it over to their server to demo next week.

## Vision in Broad Strokes


### Core Components
- A Windows server VM in Azure with a public IP and Remote Desktop access.
- A VPN for connecting to the server. Probably Pritunl (unless that install is weird on Windows but I think it's fine).
- Kasm Workspaces server. (Single instance control plane for now but start docs on high-availability clusters and elastic infrastructure)
- Whatever trust certificates we need to establish HTTPS between the user browser and the Kasm Server.

That should cover all of the basic components.

### Other Questions and Concerns
- I'd like to plug the authentication for this into EntraID and set up some test users with basic auth that they can use temporarily for a demo and just disable MFA/SSO for this particular group. That way everyone can log in instantly and get started but feel assured that since it's using Active Directory, they can plug in all of their familiar trusted identity and access management capabilities like SSO and MFA all managed my Microsoft. 
- Find out 