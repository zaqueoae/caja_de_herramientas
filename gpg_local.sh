#!/bin/bash

# Crear un directorio temporal
tempdir=$(mktemp -d)

# Configurar GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir

sudo rngd -r /dev/urandom

mkdir -p llaves_backup
rm -f llaves_backup/passwd.txt
touch llaves_backup/passwd.txt
passphrasse=$(openssl rand -base64 24)
echo "$passphrasse"
echo "$passphrasse" >> llaves_backup/passwd.txt
email=info@catinfog.com
nombre="Zaqueo Echeverria"

gpgconf --kill gpg-agent  # Required, if agent_genkey fail...
rm -rf .gnupg/* 
gpgconf --kill gpg-agent  # Required, if agent_genkey fail...

gpg --generate-key --batch <<eoGpgConf
    %echo Started!
    Key-Type: RSA
    Key-Length: 4096
    Subkey-Type: RSA
    Subkey-Length: 4096
    Subkey-Usage: sign
    Name-Real: "$nombre"
    Name-Comment: Viva Cristo Rey
    Name-Email: "$email"
    Expire-Date: 9999-12-31
    Passphrase: $(<llaves_backup/passwd.txt)
    %commit
    %echo Done.
eoGpgConf

gpg --output llaves_backup/privatekey.gpg --armor --export-secret-keys --export-options export-backup "$email"

gpg --output llaves_backup/publickey.gpg --armor --export "$email"


subkey_id=$(gpg --list-secret-keys --with-colons "$email" | awk -F: '/sub:/ {print $5; exit}')
gpg --export-secret-subkeys "$subkey_id" > llaves_backup/subkey.gpg

gpg --list-secret-keys

unset GNUPGHOME
rm -r $tempdir
cat << EOF
    Subkey-Type: RSA
    Subkey-Usage: sign
EOF
