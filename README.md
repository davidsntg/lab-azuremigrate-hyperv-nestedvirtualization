# Azure Lab - Migrate Hyper-V VMs to Azure with Azure Migrate & Nested Virtualization

This repo is a lab to simulate **Hyper-V VMs migration to Azure** using [Azure Migrate](https://docs.microsoft.com/en-us/azure/migrate/migrate-services-overview).

It simulates an Hyper-V bare-metal server using an Azure VM that hosts an Hyper-V Manager on which we create VMs. This is called nested virtualization.

Big Picture:
![Big Picture](docs/bigpicture.png)

TODO: Add all network flow matrix

## Infrastructure deployment

```bash
# Create a resource group
$ az group create --location westeurope --name MyRg
# Close repo
$ git clone https://github.com/dawlysd/lab-azuremigrate-hyperv-nestedvirtualization
$ cd lab-azuremigrate-hyperv-nestedvirtualization/bicep
# Deploy Bicep code
$ az deployment group create --resource-group MyRg --template-file infra-hyperV.bicep
```

## Hyper-V Host installation & configuration

When the deployment is done, **connect** to provisionned VM and **install Hyper-V tools**: execute following Powershell command as **Administrator**:
```powershell
Install-WindowsFeature -Name "Hyper-V" -IncludeManagementTools -Restart
```
VM will restart when installation is done.

Connect again to the machine.

To allow nested VMs communication, create an internal switch:
```powershell
New-VMSwitch –SwitchName "NATSwitch" –SwitchType Internal

Name      SwitchType NetAdapterInterfaceDescription
----      ---------- ------------------------------
NATSwitch Internal     
```

Create a new IP address and assign it to previously created switch:
```powershell
New-NetIPAddress –IPAddress "192.168.0.1" -PrefixLength 24 -InterfaceAlias "vEthernet (NATSwitch)"

IPAddress         : 192.168.0.1
InterfaceIndex    : 12
InterfaceAlias    : vEthernet (NATSwitch)
AddressFamily     : IPv4
Type              : Unicast
PrefixLength      : 24
PrefixOrigin      : Manual
SuffixOrigin      : Manual
AddressState      : Tentative
ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
SkipAsSource      : False
PolicyStore       : ActiveStore

IPAddress         : 192.168.0.1
InterfaceIndex    : 12
InterfaceAlias    : vEthernet (NATSwitch)
AddressFamily     : IPv4
Type              : Unicast
PrefixLength      : 24
PrefixOrigin      : Manual
SuffixOrigin      : Manual
AddressState      : Invalid
ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
SkipAsSource      : False
PolicyStore       : PersistentStore
```

Create NAT on created switch:
```powershell
New-NetNat –Name "NatNetwork" –InternalIPInterfaceAddressPrefix "192.168.0.0/24"

Name                             : NatNetwork
ExternalIPInterfaceAddressPrefix : 
InternalIPInterfaceAddressPrefix : 192.168.0.0/24
IcmpQueryTimeout                 : 30
TcpEstablishedConnectionTimeout  : 1800
TcpTransientConnectionTimeout    : 120
TcpFilteringBehavior             : AddressDependentFiltering
UdpFilteringBehavior             : AddressDependentFiltering
UdpIdleSessionTimeout            : 120
UdpInboundRefresh                : False
Store                            : Local
Active                           : True
```

Turn off Windows Defender Firewall
```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False 
```

TODO: explain mount E:\ data disk here

## Hyper-V Guest VM Creation

### Linux - Ubuntu

**Download** [Ubuntu Server](https://ubuntu.com/download/server) **.iso** on Hyper-V host machine. Several links here: [Ubuntu 18.04](https://releases.ubuntu.mirror.malte-bittner.eu/18.04.6/ubuntu-18.04.6-live-server-amd64.iso), [Ubuntu 20.04 LTS](https://mirrors.ircam.fr/pub/ubuntu/releases/20.04.3/ubuntu-20.04.3-live-server-amd64.iso), [Ubuntu 21.10](https://www-ftp.lip6.fr/pub/linux/distributions/Ubuntu/releases/21.10/ubuntu-21.10-live-server-amd64.iso).

Example:
```powershell
$locationFolder="E:\Hyper-V\"

# Download Ubuntu 18.04
Invoke-WebRequest -Uri "https://releases.ubuntu.mirror.malte-bittner.eu/18.04.6/ubuntu-18.04.6-live-server-amd64.iso" -OutFile "$($locationFolder)ubuntu-18.04.6-live-server-amd64.iso"

# Download Ubuntu 20.04 LTS
Invoke-WebRequest -Uri "https://mirrors.ircam.fr/pub/ubuntu/releases/20.04.3/ubuntu-20.04.3-live-server-amd64.iso" -OutFile "$($locationFolder)ubuntu-20.04.3-live-server-amd64.iso"

# Download Ubuntu 21.10
Invoke-WebRequest -Uri "https://www-ftp.lip6.fr/pub/linux/distributions/Ubuntu/releases/21.10/ubuntu-21.10-live-server-amd64.iso" -OutFile "$($locationFolder)ubuntu-21.10-live-server-amd64.iso"
```

Create new Hyper-V virtual machine with Hyper-V Manager:

![Hyper-V Machine](docs/hyper-v-create-vm01.png)

![Hyper-V Machine](docs/hyper-v-create-vm02.png)

![Hyper-V Machine](docs/hyper-v-create-vm03.png)

![Hyper-V Machine](docs/hyper-v-create-vm04.png)

![Hyper-V Machine](docs/hyper-v-create-vm05.png)

![Hyper-V Machine](docs/hyper-v-create-vm06.png)

![Hyper-V Machine](docs/hyper-v-create-vm07.png)

![Hyper-V Machine](docs/hyper-v-create-vm08.png)

![Hyper-V Machine](docs/hyper-v-create-vm09.png)

![Hyper-V Machine](docs/hyper-v-create-vm10.png)

![Hyper-V Machine](docs/hyper-v-create-vm11.png)

Configure language and keyboard, then configure Network:
![Ubuntu Machine](docs/ubuntu02.png)

![Ubuntu Machine](docs/ubuntu03.png)

![Ubuntu Machine](docs/ubuntu04.png)

It is also possible to configure guest VM network (no dhcp, static private ip address, custom gateway (to NAT) & DNS servers) by updating `/etc/netplan/99-installer-config.yaml`:
```yaml
# This is the network config writter by 'subiquity'
network:
  ethernets:
    eth0:
      addresses: [192.168.0.3/24]
      gateway4: 192.168.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
  version: 2
```

Apply the configuration:
```bash
netplan generate
netplan apply
```

View updated configuration:
```bash
ip -c a s
```
![Ubuntu Machine](docs/ubuntu04.png)

### Linux - CentOS 7.9

Download [CentOS 7 Linux](https://www.centos.org/download/) *.iso* file and create Hyper-VM Virtual Machine as seen before.

To manually update network configuration on CentOS 7 machine, update `/etc/sysconfig/network-scripts/ifcfg-eth0` file:

```bash
# static IP address on CentOS 7 or RHEL 7#
HWADDR=00:08:A2:0A:BA:B8
TYPE=Ethernet
BOOTPROTO=none
# Server IP #
IPADDR=192.168.0.5
# Subnet #
PREFIX=24
# Set default gateway IP #
GATEWAY=192.168.0.1
# Set dns servers #
DNS1=8.8.8.8
DNS2=8.8.4.4
DNS3=1.1.1.1
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
# Disable ipv6 #
IPV6INIT=no
NAME=eth0
DEVICE=eth0
ONBOOT=yes
```

Restart network service:
```bash
systemctl restart network
```

View updated configuration:
```bash
ip a s eth0
```

Screenshot:
![CentOS](docs/centos01.png)

### Windows - Server Server 2019

Download [Windows Server 2019](https://www.microsoft.com/en-US/evalcenter/evaluate-windows-server-2019?filetype=ISO) trial *.iso* file and create Hyper-VM Virtual Machine as seen before.

Apply the following network configuration on Windows VM:
![Windows](docs/windows01.png)


# Azure Migrate

Now, we suppose we have created serveral Hyper-V VMs.

Let's migrate them to Azure using Azure migrate.

First step: **Create a project**.
![Azure Migrate](docs/azure-migrate01.png)

![Azure Migrate](docs/azure-migrate02.png)

Azure Migrate is splitted in two tools:
* Azure Migrate: Discovery and assessment
* Azure Migrate: Server Migration

TODO: add the overall process and details here

## Azure Migrate - Discovery and assessment

To discover "on-premises servers", it is required to deploy an appliance:
![Azure Migrate](docs/azure-migrate03.png)

Select Hyper-V, give a name to your appliance, Generate a key and download Azure Migrate appliance .zip file:
![Azure Migrate](docs/azure-migrate04.png)

Unzip AzureMigrationAppliance.zip and **Import** this appliance on Hyper-V:
![Import Appliance](docs/importappliance01.png)

![Import Appliance](docs/importappliance02.png)

![Import Appliance](docs/importappliance03.png)

![Import Appliance](docs/importappliance04.png)

![Import Appliance](docs/importappliance05.png)

![Import Appliance](docs/importappliance06.png)

Start appliance VM & connect:
![Import Appliance](docs/importappliance07.png)

![Import Appliance](docs/importappliance08.png)

After signin, Configure Network Connections:
![Import Appliance](docs/importappliance09.png)

**Note**: on a "corporate environment" where sometimes machines do not have access to the Internet, it is possible to set up a proxy.

Edge will then launch automatically:
![Import Appliance](docs/importappliance10.png)

Execute prerequisites:
![Azure Migrate Appliance](docs/azuremigrateappliance04.png)

Paste the key given on Azure Portal and Login:
![Azure Migrate Appliance](docs/azuremigrateappliance05.png)

Continue with [Azure Device Login](https://www.microsoft.com/devicelogin):
![Azure Migrate Appliance](docs/azuremigrateappliance06.png)

![Azure Migrate Appliance](docs/azuremigrateappliance07.png)

![Azure Migrate Appliance](docs/azuremigrateappliance08.png)

On Hyper-V host VM: 
* Create an *azuremigrateuser* account, member of bellow groups:
  * Administrators
  * Hyper-V Administrators
  * Performance Monitor Users
  * Remote Management Users

Screenshot:
![Azure Migrate User](docs/azuremigrate_rights.png)

* Enable also Powershell Remote:
  * ```powershell Enable-PSRemoting -force```

Back to Azure Migrate Appliance, add *azuremigrateuser* credentials:
![Azure Migrate Appliance](docs/azuremigrateappliance09.png)

Add single item: give previously created *azuremigrateuser* and IP Address of Hyper-V host: `192.168.0.1`
![Azure Migrate Appliance](docs/azuremigrateappliance10.png)

Start discovery:
![Azure Migrate Appliance](docs/azuremigrateappliance11.png)

When discovery is finished, go back to the Azure portal on Azure Migrate:
![Azure Migrate Portal](docs/azure-migrate05.png)

We can see discovered servers.

Let's create assessment now:
![Azure Migrate Portal](docs/azure-migrate06.png)
  
![Assessment](docs/assessment01.png)

![Assessment](docs/assessment02.png)

To view assessment result, click here:
![Assessment](docs/assessment03.png)

![Assessment](docs/assessment04.png)

![Assessment](docs/assessment05.png)
Let's now play with the migration tools!

## Azure Migrate: Server Migration

![Discover](docs/discover01.png)

Select a target region:
![Discover](docs/discover02.png)

Download the Azure Site Recovery Provider software installer and the registration key file on Hyper-V host VM:
![Discover](docs/discover03.png)

![Discover](docs/discover04.png)
Install the Azure Site Recovery Provider:
![Azure Site Recovery Provider Setup](docs/azuresiterecoveryprovidersetup01.png)

![Azure Site Recovery Provider Setup](docs/azuresiterecoveryprovidersetup02.png)

![Azure Site Recovery Provider Setup](docs/azuresiterecoveryprovidersetup03.png)

Register using the key file:
![Azure Site Recovery Provider Setup](docs/azuresiterecoveryprovidersetup04.png)

![Azure Site Recovery Provider Setup](docs/azuresiterecoveryprovidersetup05.png)

![Azure Site Recovery Provider Setup](docs/azuresiterecoveryprovidersetup06.png)

Wait untill the Hyper-V host appears Connected on Azure portal and **Finalize registration**:
![Discover](docs/discover05.png)

Let's now replicate a Hyper-V VM to Azure.

First of all, we need to create a new resource group that will receive replicated Hyper-V VMs.
In this resource group, we need to provision:
* A virtual Network
* A storage account (**without blob soft delete enabled**)

You can do it manually or just execute:
```bash
# Create a resource group
$ az group create --location northeurope --name TargetRG
# Deploy Bicep code
$ az deployment group create --resource-group TargetRG --template-file infra-target.bicep
```

![Replicate](docs/replicate01.png)

![Replicate](docs/replicate02.png)

![Replicate](docs/replicate03.png)

Select Hyper-V VMs to migrate:
![Replicate](docs/replicate04.png)

Select target RG, VNet and Storage Account (used for diagnostics)
![Replicate](docs/replicate05.png)

Define an Azure VM Name and select OS Type:
![Replicate](docs/replicate06.png)

Select disks to replicate:
![Replicate](docs/replicate07.png)

Define tags:
![Replicate](docs/replicate08.png)

Replicate:
![Replicate](docs/replicate09.png)

Follow replication status:
![Replicate](docs/replicate10.png)

When replication is done, we can perform test migration or migration directly.

![Migrate](docs/migrate01.png)

Let's migrate  VMs directly:
![Migrate](docs/migrate02.png)

Wait untill finish:
![Migrate](docs/migrate03.png)

Observe result in target resource group:
![Migrate](docs/migrate04.png)

Check Azure VMs are running, connect to them and check appliancations are Running.


# Sources

* https://www.cyberciti.biz/faq/howto-setting-rhel7-centos-7-static-ip-configuration/
* https://www.piesik.me/2019/02/04/Azure-Nested-Virtualization-Internet-Connection/#
* https://www.nakivo.com/blog/hyper-v-nested-virtualization-on-azure-complete-guide/
* https://docs.microsoft.com/en-US/azure/migrate/tutorial-discover-hyper-v