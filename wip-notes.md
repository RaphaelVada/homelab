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
