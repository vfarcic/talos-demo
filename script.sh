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

# We don't support the format of your image. Please try again with a supported image format (raw, qcow2, vdi, vhdx, or vmdk).

# Replace `[...]` with the image ID
export IMAGE_ID=[...]

doctl compute load-balancer create \
    --region nyc3 \
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

# TODO: Prerequisite setup explanation

talosctl gen config talos-demo https://$LB_IP:443

# TODO: Cluster API video

cat controlplane.yaml

cat worker.yaml

cat talosconfig

for N in 1 2 3
do
    doctl compute droplet create \
        --region nyc3 \
        --image $IMAGE_ID \
        --size s-2vcpu-4gb \
        --enable-private-networking \
        --tag-names talos-demo-cp \
        --user-data-file controlplane.yaml \
        --ssh-keys $SSH_KEY_FINGERPRINT \
        talos-demo-cp-$N

    doctl compute droplet create \
        --region nyc3 \
        --image $IMAGE_ID \
        --size s-2vcpu-4gb \
        --enable-private-networking \
        --tag-names talos-demo-worker \
        --user-data-file worker.yaml \
        --ssh-keys $SSH_KEY_FINGERPRINT \
        talos-demo-worker-$N
done

export CP_1_IP=$(doctl compute droplet get \
    --format PublicIPv4 \
    talos-demo-cp-1 \
    | tail -1)

talosctl --talosconfig talosconfig \
    config endpoint $CP_1_IP

talosctl --talosconfig talosconfig \
    config node $CP_1_IP

talosctl --talosconfig talosconfig \
    bootstrap

talosctl --talosconfig talosconfig \
    kubeconfig kubeconfig.yaml

kubectl --kubeconfig kubeconfig.yaml \
    get nodes

# Orig: Start

talosctl cluster create

kubectl get nodes

curl https://github.com/talos-systems/talos/releases/latest/download/talos-amd64.iso -L -o /home/alfadil/DevOps/talos/_out/talos-amd64.iso

TALOS_LOC="/home/alfadil/DevOps/talos" 
TALOS_ISO="/home/alfadil/DevOps/talos/_out/talos-amd64.iso"


# prepare the kvm machines
VM="k8s-master"
IP_ADDRESS="192.168.122.20"
MAC_ADDRESS="52:54:00:f2:d3:20" 

virsh net-update --network default \
     --command add-last --section ip-dhcp-host \
     --xml "<host mac='${MAC_ADDRESS}' name='${VM}' ip='${IP_ADDRESS}'/>" \
     --live --config

virt-install --name ${VM} \
     --ram 2048 --vcpus 2 --os-type linux --os-variant ubuntu20.04 \
     --network bridge=virbr0,mac=${MAC_ADDRESS} \
     --disk path=${TALOS_LOC}/${VM}.qcow2,size=20,device=disk,bus=scsi \
     --cdrom ${TALOS_ISO} \
     --console=pty,target.type=serial --graphics none --noautoconsole   



VM="k8s-node1"
IP_ADDRESS="192.168.122.21"
MAC_ADDRESS="52:54:00:f2:d3:21" 

virsh net-update --network default \
     --command add-last --section ip-dhcp-host \
     --xml "<host mac='${MAC_ADDRESS}' name='${VM}' ip='${IP_ADDRESS}'/>" \
     --live --config

virt-install --name ${VM} \
     --ram 2048 --vcpus 2 --os-type linux --os-variant ubuntu20.04 \
     --network bridge=virbr0,mac=${MAC_ADDRESS} \
     --disk path=${TALOS_LOC}/${VM}.qcow2,size=20,device=disk,bus=scsi \
     --cdrom ${TALOS_ISO} \
     --console=pty,target.type=serial --graphics none --noautoconsole   


VM="k8s-node2"
IP_ADDRESS="192.168.122.22"
MAC_ADDRESS="52:54:00:f2:d3:22" 

virsh net-update --network default \
    --command add-last --section ip-dhcp-host \
    --xml "<host mac='${MAC_ADDRESS}' name='${VM}' ip='${IP_ADDRESS}'/>" \
    --live --config

virt-install --name ${VM} \
     --ram 2048 --vcpus 2 --os-type linux --os-variant ubuntu20.04 \
     --network bridge=virbr0,mac=${MAC_ADDRESS} \
     --disk path=${TALOS_LOC}/${VM}.qcow2,size=20,device=disk,bus=scsi \
     --cdrom ${TALOS_ISO} \
     --console=pty,target.type=serial --graphics none --noautoconsole   


#Generate the machine configurations to use for installing Talos and Kubernete
talosctl gen config talos-virsh-cluster https://192.168.122.20:6443 --output-dir ${TALOS_LOC}/_outs





talosctl apply-config --insecure --nodes 192.168.122.20 --file ${TALOS_LOC}/_outs/controlplane.yaml


talosctl apply-config --insecure --nodes 192.168.122.21 --file ${TALOS_LOC}/_outs/worker.yaml

talosctl apply-config --insecure --nodes 192.168.122.22 --file ${TALOS_LOC}/_outs/worker.yaml

talosctl --talosconfig=${TALOS_LOC}/_outs/talosconfig config endpoint 192.168.122.20 192.168.122.21 192.168.122.22


# give it time
talosctl --talosconfig=${TALOS_LOC}/_outs/talosconfig --nodes 192.168.122.20 version


talosctl config merge ${TALOS_LOC}/_outs/talosconfig

talosctl bootstrap --nodes 192.168.122.20

#Using the cluster
export CONTROL_PLANE_IP=192.168.122.20
talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP

talosctl kubeconfig

kubectl get nodes

kubectl create deployment nginx --image=nginx

# Orig: End

# TODO: Demonstrate security

# TODO: Demonstrate predictability

# TODO: Demonstrate evolvability

##############
# Conclusion #
##############

# Cons:
# - TODO:

# Pros:
# - TODO:

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
