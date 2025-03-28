# Current working notes

## using vault for ssh keys

I just generated an ssh key. Then I put it into my vault.
For testing i removed it and pulled it from the vault.
For use in ssl connections I added an symlink in dhe .ssh directory.

Hopefully it works.

I want to use that key later for ansible.

```
ssh-keygen -t ed25519 -f /secrets/ssh_bootstrap-ssh -N ""
vault-sync.sh to-vault

rm -rf *
vault-sync.sh from-vault

chmod 600 /secrets/ssh_bootstrap-ssh
chmod 600 /secrets/ssh_bootstrap-ssh.pub

ln -s /secrets/ssh_bootstrap-ssh /root/.ssh/id_ed25519
ln -s /secrets/ssh_bootstrap-ssh.pub /root/.ssh/id_ed25519.pub

chmod 600 /root/.ssh/id_ed25519
chmod 600 /root/.ssh/id_ed25519.pub

ssh-copy-id -i /secrets/ssh_bootstrap-ssh.pub root@hyper03.fritz.box
```

I need some script "move to vault". I want to just point a file, which should be synced with the vault.
The script should move the file to /secrets/ and add an symlink to the original location. Finally it should sync it to vault.

## Updating my proxmox

Basically I added the community repos through the web frontend. On the way I noticed a few todos for later:

- [] fix users and usermanagement on proxmox
- [] add proxmox to monitoring
- [] automate updating the cluster

## localizing my devcontainer

I should configure the default shell and check the python installation

### installing ansible

following along and jims garage youtube channel:
https://www.youtube.com/watch?v=TpVbjPwWtyA&list=PLXHMZDvOn5sW-EXm2Ur5TroSatW-t0Vz_
https://github.com/JamesTurland/JimsGarage/tree/main/Ansible/Installation

seems a bit simple in the end. I missed how to set up project actually with ansible and a good introduction into roles, inventories and so on.

But actually whats neat is that the inventory is like our deployment nodes and the roles could be our logical layer. (Thinking of architecture documentation)

also i need to incooperate ansible vault or replace it with hashicorp vault

## installing dns

I just switched my idea. I first started out with bind9 in mind.
https://www.youtube.com/watch?v=syzwLwE3Xq4

but i wanted something simpler.
I stumbled on coreDNS. This is allready used by k8s clusters.
https://medium.com/@bensoer/setup-a-private-homelab-dns-server-using-coredns-and-docker-edcfdded841a
https://coredns.io/

this is way more simplistic.

https://coredns.io/plugins/tls/

so as upstream dns i chose quad9
i later want to enable dns over tls

IPv4
9.9.9.9

149.112.112.112

IPv6
2620:fe::fe

2620:fe::9

HTTPS
https://dns.quad9.net/dns-query

TLS
tls://dns.quad9.net

# storing secrets

i added some scripts, to make files to secrets:

- moving to secret directory on ramdisk
- placing symlink on current place
- adding filesync to startup
- adding file to git-ignore
- syncing the vault

I also need some functions to remove the files from secrets
maybe there is still some issue with git ignore, if that are files from outside the workspace
Also currently i sync the whole vault. maybe i chould only synced changed files
finally I should remove files from vault
and also i might want to sync the secrets on git commit

# btw

- I need to relocate the \_vault-volumes to be outside of the dev container
- I should support spinning up the dev container and then have the option
  - excecute first init from there
  - load current settings
- maybe i could bake in nfs mount into my docker-compose?
