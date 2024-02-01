#!/bin/bash
#######################################################
#Variables gpg. Modifica esto a tu gusto
email="info@pacopepe3242335.com"
nombre="Paco Pepe"
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

#Exporto la llave privada y las subclaves para guardarlas a buen recaudo
gpg --pinentry-mode loopback --passphrase "$(<llaves_backup/passwd.txt)" --output llaves_backup/privatekey.gpg --armor --export-secret-keys --export-options export-backup "$email"


# Obtenemos las líneas que contienen información de subclaves
subkey_lines=$(gpg --list-keys $keyid | awk '/sub/')

while IFS= read -r line; do
    # Extraemos el ID de la subclave y su uso
    subkeyid=$(echo $line | awk '{print $2}' | cut -d'/' -f2)
    usage=$(echo $line | awk '{print $1}')

    # Determinamos el nombre del archivo basado en el uso de la subclave
    filename=""
    case $usage in
        "ssb")
            filename="sign"
            ;;
        "ssb>u")
            filename="auth"
            ;;
        "ssb/e")
            filename="encrypt"
            ;;
        *)
            filename=$subkeyid  # si no podemos determinar el uso, usamos el ID de la subclave
            ;;
    esac

    # Exportamos la subclave
    gpg --output llaves_backup/subkey_${filename}.pgp --export-secret-subkeys ${subkeyid}!
done <<< "$subkey_lines"



#Exporto la llave pública
gpg --output llaves_backup/publickey.gpg --armor --export "$email"

#Envío la llave publica a un servidor publico
#gpg --keyserver keyserver.ubuntu.com --send-keys "$keyid"

#Paro la generación de entropía
pidrngd=$(pgrep rngd)
sudo kill -9 "$pidrngd"

#borro el directorio de gpg temporal y vuelvo a colocar el principal
unset GNUPGHOME
rm -r $tempdir
