# Source: https://gist.github.com/a03d2dbe0ef6c964d9c5ef859a2dabdd

#########
# TODO: #
# TODO: #
#########

# Additional Info:
# - https://www.talos.dev/
# - TODO:

#########
# Intro #
#########

# Linux designed for Kubernetes.

# Security: All API access is secured with mutual TLS (mTLS) authentication.
# Predictability: Talos eliminates configuration drift, reduces unknown factors by employing immutable infrastructure ideology, and delivers atomic updates.
# Evolvability: Talos simplifies your architecture, increases your agility, and makes always delivers current stable Kubernetes and Linux versions.

#########
# Setup #
#########

# If using amd64 architecture
export ARCH=amd64

# If using arm64 architecture
export ARCH=arm64

curl -Lo /usr/local/bin/talosctl \
    "https://github.com/talos-systems/talos/releases/latest/download/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-$ARCH"

chmod +x /usr/local/bin/talosctl

curl https://github.com/talos-systems/talos/releases/latest/download/digital-ocean-amd64.tar.gz \
    -L -o digital-ocean-amd64.tar.gz

tar -xzvf digital-ocean-amd64.tar.gz

rm digital-ocean-amd64.tar.gz

gzip disk.raw

# Upload the image to DigitalOcean

rm disk.raw.gz

# now upload the image
# you have to do it manually through the browser
# and make it public


#create the image

# Replace `[...]` with the region
export REGION=[...]
doctl compute image create \
    --region $REGION \
    --image-description talos-digital-ocean-tutorial \
    --image-url https://talos-tutorial.$REGION.digitaloceanspaces.com/disk.raw.gz \
    Talos

# Replace `[...]` with the image ID
export IMAGE_ID=[...]


# Create the load balancer
doctl compute load-balancer create \
    --region $REGION \
    --name talos-demo \
    --tag-name talos-demo \
    --health-check protocol:tcp,port:6443,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:5,unhealthy_threshold:3 \
    --forwarding-rules entry_protocol:tcp,entry_port:443,target_protocol:tcp,target_port:6443

# Replace `[...]` with the LB ID
export LB_ID=[...]

export LB_IP=$(\
    doctl compute load-balancer get \
    --format IP $LB_ID | tail -1)

echo $LB_IP

# Repeat the previous two commands if the output is empty (the LB has not yet been created)

# Although SSH is not used by Talos, DigitalOcean still requires that an SSH key be associated with the droplet. 
# Create a dummy key that can be used to satisfy this requirement.
# Replace `[...]` with the public key
doctl compute ssh-key create devops-toolkit --public-key [...]

# Replace `[...]` with your SSH key fingerprint
export SSH_KEY_FINGERPRINT=[...]

##########
# TODO:: #
##########

# Bare metal platforms:
# - Digital Rebar
# - Equinix Metal
# - Matchbox
# - Sidero
# Virtualized platforms:
# - Hyper-V
# - KVM
# - Proxmox
# - VMware
# - Xen
# Cloud platforms:
# - AWS
# - Azure
# - DigitalOcean
# - GCP
# - Hetzner
# - Nocloud
# - Openstack
# - Scaleway
# - UpCloud
# - Vultr
# Local platforms
# - Docker
# - QEMU
# - VirtualBox

# Using the DNS name of the loadbalancer created earlier, generate the base configuration files for the Talos machines:
# This step generates three files which are used to configure the the k8s nodes
# The Controlplane Machine Config describes the configuration of a Talos server on which the Kubernetes Controlplane should run. 
# The Worker Machine Config describes workload servers.
# The talosconfig file is your local client configuration file
talosctl gen config talos-demo https://$LB_IP:443

# TODO: Cluster API video

cat controlplane.yaml

cat worker.yaml

cat talosconfig

# Select the droplet size for control plan and workers

export CTRL_SIZE=[...]
export WORKER_SIZE=[...]

for N in 1 2 3
do
    doctl compute droplet create \
        --region $REGION \
        --image $IMAGE_ID \
        --size $CTRL_SIZE \
        --enable-private-networking \
        --tag-names talos-demo \
        --user-data-file controlplane.yaml \
        --ssh-keys $SSH_KEY_FINGERPRINT \
        talos-demo-cp-$N

    doctl compute droplet create \
        --region $REGION \
        --image $IMAGE_ID \
        --size $WORKER_SIZE \
        --enable-private-networking \
        --user-data-file worker.yaml \
        --ssh-keys $SSH_KEY_FINGERPRINT \
        talos-demo-worker-$N
done

# Bootstrap Etcd
# To configure talosctl we will need the control planes IP:
for N in 1 2 3
do
    export CP_IP_$N=$(doctl compute droplet get \
        --format PublicIPv4 \
        talos-demo-cp-$N \
        | tail -1)
    export WK_IP_$N=$(doctl compute droplet get \
        --format PublicIPv4 \
        talos-demo-worker-$N \
        | tail -1)
    
done


# Set the endpoint and node of talosctl:
talosctl --talosconfig talosconfig \
    config endpoint $CP_IP_1 

talosctl --talosconfig talosconfig \
    config node $CP_IP_1

# Bootstrap etcd:
talosctl --talosconfig talosconfig bootstrap

# Retrieve the kubeconfig
talosctl --talosconfig talosconfig kubeconfig .

kubectl --kubeconfig kubeconfig get nodes

kubectl --kubeconfig kubeconfig create deployment nginx --image=nginx

# Orig: End

# security
# you simply cannot change anything on any of the nodes 
# you cannot ssh to it so no way to install anything
doctl compute ssh talos-demo-cp-2

# this will always fail with
# Error: fork/exec /usr/bin/ssh: permission denied

# predictability
# just add a new worker node
# or remove a node and the cluster just works

doctl compute droplet create \                                                                                      at 22:08:01
    --region $REGION \
    --image $IMAGE_ID \
    --size $WORKER_SIZE \
    --enable-private-networking \
    --user-data-file worker.yaml \
    --ssh-keys $SSH_KEY_FINGERPRINT \
    talos-demo-worker-4

# evolvability
# in term of upgrade the kublet version
# you can easily do it by running

talosctl --talosconfig talosconfig --nodes $CP_IP_2 upgrade-k8s --to 1.23.1

# the current version being 1.23
# it's this simple 



##############
# Conclusion #
##############

# Pros:
#   - A fast way to create a k8s cluster on many platforms.
#   - Secure by design
#   - No big maintenance overhead(you can't break it).

# Cons:
# - POOR documentation.
# - Slow to start

###########
# Destroy #
###########

for N in 1 2 3
do
    doctl compute droplet \
        delete talos-demo-cp-$N \
        --force

    doctl compute droplet \
        delete  talos-demo-worker-$N \
        --force
done

doctl compute load-balancer \
    delete $LB_ID \
    --force
