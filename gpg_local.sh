#!/bin/bash
#######################################################
#Variables gpg. Modifica esto a tu gusto
email="info@catinfog.com"
nombre="Zaqueo Echeverria"
#######################################################

# Crear un directorio temporal
tempdir=$(mktemp -d)

# Configurar GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir


mkdir -p llaves_backup
rm -f llaves_backup/passwd.txt
touch llaves_backup/passwd.txt
passphrasse=$(openssl rand -base64 24)
echo "$passphrasse"
echo "$passphrasse" >> llaves_backup/passwd.txt

#Genero entropía
sudo rngd -r /dev/urandom

#Reinicio el agente gpg
gpgconf --kill gpg-agent  # Required, if agent_genkey fail...
gpgconf --kill gpg-agent  # Required, if agent_genkey fail...

#Creo la llave privada y las subclaves
gpg --generate-key --batch <<eoGpgConf
    Key-Type: RSA
    Key-Length: 4096
    Name-Real: "$nombre"
    Name-Comment: Viva Cristo Rey
    Name-Email: "$email"
    Expire-Date: 9999-12-31
    Passphrase: $(<llaves_backup/passwd.txt)
    %commit
    Subkey-Type: RSA
    Subkey-Length: 4096
    Subkey-Usage: sign
    %commit
    Subkey-Type: RSA
    Subkey-Length: 4096
    Subkey-Usage: encrypt
    %commit
    Subkey-Type: RSA
    Subkey-Length: 4096
    Subkey-Usage: auth
    %commit
eoGpgConf

#Obtengo el id de la llave privada
keyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Firmo la llave publica
gpg --sign-key "$keyid"

#Exporto la llave privada
gpg --pinentry-mode loopback --passphrase "$(<llaves_backup/passwd.txt)" --output llaves_backup/privatekey.gpg --armor --export-secret-keys --export-options export-backup "$email"

#Exporto la llave pública
gpg --output llaves_backup/publickey.gpg --armor --export "$email"

#Envío la llave publica a un servidor publico
gpg --keyserver keyserver.ubuntu.com --send-keys "$keyid"

#Paro la generación de entropía
pidrngd=$(pgrep rngd)
sudo kill -9 "$pidrngd"

#borro el directorio de gpg temporal y vuelvo a colocar el principal
unset GNUPGHOME
rm -r $tempdir
