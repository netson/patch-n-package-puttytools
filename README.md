# Patch 'n Package puttytools
Provides a patched version of puttygen which allows accepting passwords via cli arguments.

### Why?
I use Ansible to manage my server configurations and I'm writing a plugin which allows using KeePass as a store for secrets (instead of using Ansible Vault). This plugin also allows you to generate secrets on the fly, including SSH keys. Since some of my customers use windows systems/putty, I also wanted the plugin to be able to automatically convert SSH keys to the PuTTY format. However, since puttygen by default does not accept password entered on the command line, I needed a solution, which is this patch.

<pre>
$ puttygen --help
PuTTYgen: key generator and converter for the PuTTY tools
Release 0.70
Usage: puttygen ( keyfile | -t type [ -b bits ] ) <strong>[ -N passphrase ]</strong>
                [ -C comment ] [ -P ] [ -q ]
                [ -o output-keyfile ] [ -O type | -l | -L | -p ]
  -t    specify key type when generating (ed25519, ecdsa, rsa, dsa, rsa1)
  -b    specify number of bits when generating key
  -C    change or specify key comment
  -P    change key passphrase
  -q    quiet: do not display progress bar
  <strong>-N    new or existing passphrase</strong>
  -O    specify output type:
           private             output PuTTY private key format
           private-openssh     export OpenSSH private key
           private-openssh-new export OpenSSH private key (force new format)
           private-sshcom      export ssh.com private key
           public              RFC 4716 / ssh.com public key
           public-openssh      OpenSSH public key
           fingerprint         output the key fingerprint
  -o    specify output file
  -l    equivalent to `-O fingerprint'
  -L    equivalent to `-O public-openssh'
  -p    equivalent to `-O public'
  --old-passphrase file
        specify file containing old key passphrase
  --new-passphrase file
        specify file containing new key passphrase
  --random-device device
        specify device to read entropy from (e.g. /dev/urandom)
</pre>

### Credits
I used the information from this blog as a starting point: 
https://itefix.net/content/puttygen-patch-entering-passphrases-command-line
