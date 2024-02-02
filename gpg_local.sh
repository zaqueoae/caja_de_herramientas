#!/bin/bash

# Explanation:
#
# This script generates unattended with gpg a private key and 3 subkeys.
# The primary private key, public key and the 3 subkeys are exported to separate files. 
# This is not usual, since gpg "forces" all private keys to be exported together. To achieve this I had to use a "little trick".
# The passphrase is noted in 1 txt file.
# The public key is imported to a public server.
# To do all this I use temporary directories, so when I'm done there is no trace left. Only the exported files remain.


#######################################################
#gpg variables. Modify this
email="info@pacopepe3242335.com"
nombre="Paco Pepe"
tag="Viva Cristo Rey"
lenghtkey="4096"
typekey="RSA"
expiregpg="9999-12-31"
#######################################################

# Crear un directorio temporal
tempdir=$(mktemp -d)

# Configurar GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir

rm -rf llaves_backup
mkdir -p llaves_backup
passphrase=$(openssl rand -base64 24)
echo "$passphrase" >> llaves_backup/passwd.txt

#Genero entropía
sudo rngd -r /dev/urandom

#Reinicio el agente gpg
gpgconf --kill gpg-agent  # Required, if agent_genkey fail...
gpgconf --kill gpg-agent  # Required, if agent_genkey fail...

#Creo la llave privada
gpg --generate-key --batch <<eoGpgConf
    Key-Type: $typekey
    Key-Length: $lenghtkey
    Name-Real: $nombre
    Name-Comment: $tag
    Name-Email: $email
    Expire-Date: $expiregpg
    Passphrase: $(<llaves_backup/passwd.txt)
    %commit
eoGpgConf


#Exporto la llave privada
gpg --pinentry-mode loopback --passphrase "$(<llaves_backup/passwd.txt)" --output llaves_backup/privatekey.gpg --armor --export-secret-keys --export-options export-backup "$email"

#Exporto la llave pública
gpg --output llaves_backup/publickey.gpg --armor --export "$email"

#Obtengo el id de la llave privada
keyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Envío la llave publica a un servidor publico
gpg --keyserver keyserver.ubuntu.com --send-keys "$keyid"





########################################################################################
#Subclaves
#Genero las 3 subclaves
########################################################################################

#Primero la subkey de firmas
#Averiguo la huella de la llave privada
FPR=$(gpg --fingerprint "$keyid" | sed -n '/^\s/s/\s*//p')
#Genero la subkey
gpg --pinentry-mode loopback --batch --passphrase "$passphrase" --quick-add-key "$FPR" rsa4096 sign 1y
#Averiguo la huella de la subclave
subkey_fingerprint=$(gpg --list-keys --with-subkey-fingerprint "$email" | awk '/sub/{getline; print}' | tail -1 | sed 's/ //g')
#Exporto la llave
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --export-secret-subkeys "$subkey_fingerprint"! > llaves_backup/subkey_sign.pgp

#Ahora voy a por la subkey de encriptado
tempdir2=$(mktemp -d)
# Configurar GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir2

#Importo de nuevo la llave principal
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/privatekey.gpg
#Obtengo el id de la llave privada
keyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)
#Averiguo la huella de la llave principal
FPR=$(gpg --fingerprint "$keyid" | sed -n '/^\s/s/\s*//p')
#Genero la subkey
gpg --pinentry-mode loopback --batch --passphrase "$passphrase" --quick-add-key "$FPR" rsa4096 encr 1y
#Averiguo la huella de la subclave
subkey_fingerprint=$(gpg --list-keys --with-subkey-fingerprint "$email" | awk '/sub/{getline; print}' | tail -1 | sed 's/ //g')
#Exporto la subkey
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --export-secret-subkeys "$subkey_fingerprint"! > llaves_backup/subkey_encrypt.pgp


tempdir3=$(mktemp -d)
# Configurar GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir3

#Ahora voy a por la subkey de autenticado
#Importo de nuevo la llave principal
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/privatekey.gpg
#Obtengo el id de la llave privada
keyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)
#Obtengo la huella de la llave privada
FPR=$(gpg --fingerprint "$keyid" | sed -n '/^\s/s/\s*//p')
#Genero la subkey
gpg --pinentry-mode loopback --batch --passphrase "$passphrase" --quick-add-key "$FPR" rsa4096 auth 1y
#Averiguo la huella de la subclave
subkey_fingerprint=$(gpg --list-keys --with-subkey-fingerprint "$email" | awk '/sub/{getline; print}' | tail -1 | sed 's/ //g')
#Exporto la subkey
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --export-secret-subkeys "$subkey_fingerprint"! > llaves_backup/subkey_auth.pgp

#Me cargo las variables con contenido sensible
unset passphrase
unset FPR

#Paro la generación de entropía
pidrngd=$(pgrep rngd)
sudo kill -9 "$pidrngd"

#borro el directorio de gpg temporal y vuelvo a colocar el principal
unset GNUPGHOME
rm -r $tempdir
rm -r $tempdir2
rm -r $tempdir3

