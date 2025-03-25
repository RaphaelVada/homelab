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

68ee76077907# chmod 600 /root/.ssh/id_ed25519
68ee76077907# chmod 600 /root/.ssh/id_ed25519.pub
```
