# AWS EC2 Minecraft Server Automatic Install Script

## Introduction

This script deploys and installs a dedicated Minecraft (version 26.2) server on
AWS, running the application on an EC2 instance and creating the VPC infrastructure
necessary for outside players to connect to this server. An SSH key is also created
for remote management of this server.

This script works by first checking for the required AWS and Terraform CLIs, as
well as an SSH public key at `~/.ssh/minecraftserver.pub`. If this key is
absent, `ssh-keygen` is then called to create a new SSH key pair for the server.
In either case, the script will pass the public key as an environment variable
to use with Terraform. The script then calls `sfxshgen.sh`, which compiles the
`ec2setup.sh` and `ec2setup-mcsvc.sh` setup scripts along with the `minecraft.service`
service description file into a single shell script (with each file encoded as a
base64 string). That script itself is then encoded to base64 to be passed as user
data to AWS by setting another environment variable for Terraform to use.
The script then calls `terraform apply` to provision the AWS resources. The EC2
instance will run the compiled shell script, which will decode the aforementioned
setup scripts and service description file and then run `ec2setup.sh`, which 
(along with the other script and service file) will create a service account
with restricted permissions, install the Minecraft server to the `/opt/minecraft`
directory, configure it to run as a service under the restricted account, and
reboot the machine. After the server is rebooted, the script finishes by writing
its public IP address to standard output. A FIFO is also created in 
`/opt/minecraft/serverinput`, which links to the standard input of the Minecraft
server application for management. Users in the `minecraft` group can execute
server console commands by writing to that FIFO.

Note that it may take up to 3 minutes from when the script finishes for the server
to be available.

## Prerequisites

To run these scripts, you will need a Linux-based system with the following:

- AWS CLI (tested on version 2.36.24)
- Terraform CLI (tested on version 1.15.8)
- An OpenSSH installation with `ssh-keygen` (tested on OpenSSH 10.0p2), or an existing SSH key pair
- An AWS account with its credentials installed

Different versions of the above tools may work, but are not guaranteed to do so.

You should also review the [Minecraft end-user license agreement](https://www.minecraft.net/en-us/eula) before installing the server.

## Resources Created

This script will create the following AWS resources; their usage charges may apply:

- One EC2 `t3.small` instance with Amazon Linux in the `us-west-2` region
- One VPC with the following:
  - The CIDR block of `10.0.0.0/24`
  - One Internet Gateway
  - One Route Table, with a main route table association
  - One subnet in availability zone `us-west-2a` with the CIDR block `10.0.0.0/28`, which automatically assigns public IPv4 addresses
  - One security group that allows incoming SSH (port 22/TCP) and Minecraft (port 25565/TCP/UDP) traffic, as well as all outgoing traffic to pass
  - One network interface connecting the EC2 instance to the subnet mentioned above, with the aforementioned security groups

The prices (in US dollars, as of 15 August 2026) for these services are:

| Service      | Per Hour | Per Day  | Per 30 Days |
|--------------|----------|----------|-------------|
| EC2 t3.small | $ 0.0208 | $ 0.4992 | $     14.98 |
| Public IPv4  | $ 0.0050 | $ 0.1200 | $      3.60 |
| Total        | $ 0.0258 | $ 0.6192 | $     18.58 |

These services are free tier eligible; these services will draw from your AWS
plan's credits before your account is closed (for free plans) or your payment
method is charged (for paid plans).

## Deployment

To create the server, simply run:

```
./deploy.sh
```

This install script deploys the above resources and configures the server completely
automatically. Once the script completes, the server's public IP address will be 
written to standard output, while the server's SSH keys will be written to 
`~/.ssh/minecraftserver` (for the private key) and to `~/.ssh/minecraftserver.pub`
(for the public key).

After the script completes, the EC2 instance may take a few minutes before it is
ready to accept Minecraft players. Once the server is ready, players may join
by entering the server IP address (displayed at the end of the script) into
Minecraft's multiplayer menu by selecting either *Add Server* (to save this IP address)
or *Direct Connection* (to connect without saving).

## Management

Once the server is deployed, the SSH key at `~/.ssh/minecraftserver` can be used
to connect to the server with the username `ec2-user`:

```
ssh -i ~/.ssh/minecraftserver ec2-user@<ip-address>
```

The Minecraft server service can be managed as the systemd service `minecraft.service`.
For example, to restart the server:

```
sudo systemctl restart minecraft.service
```

The Minecraft server files are located at `/opt/minecraft/`; any user in the
`minecraft` group can modify this directory, including the default `ec2-user`. 
Additionally, a FIFO that connects to the server's standard input is available
at `/opt/minecraft/serverinput`; any user in the `minecraft` group can write to
this to execute server console commands. For example, the following can be used
to kick the user `mcplayer`:

```
echo "/kick mcplayer" > /minecraft/serverinput
```

## Deletion

To delete the server, simply run:

```
terraform destroy
```

This will delete all infrastructure created with the `deploy.sh` script and
thus stop any further charges incurred on your AWS account. Make sure that your
Minecraft data is backed up elsewhere if desired, as this cannot be undone.
A new server can be deployed by running `deploy.sh` again.

## Resources used

- AWS Learner Lab (for first manually creating the infrastrucure, then analyzing the created infrastructre to figure out what resources need to be created in this script)

- https://registry.terraform.io/providers/hashicorp/aws/latest/docs (for finding the corresponding Terraform code for each AWS resource, and for updating code for use with version 6 of the AWS provider)

- https://developer.hashicorp.com/terraform (for Terraform concepts not specific to AWS)

- https://www.freedesktop.org/software/systemd/man/255/systemd.service.html (for configuring ExecStop for the Minecraft systemd service)

- https://linux.die.net/man/1/bash (for writing Bash scripts and to implement read/write I/O redirection with the FIFO (since those block until both sides are opened))

- My original System Administration Course Project part 1 documentation (for commands needed to configure the EC2 instance, so those can be put into a script)

- https://aws.amazon.com/ec2/pricing/on-demand/ and https://aws.amazon.com/vpc/pricing/ for AWS EC2 instance and public IPv4 address pricing