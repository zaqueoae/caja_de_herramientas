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
echo "$passphrasse" >> llaves_backup/passwd.txt
passphrasse_subkeys=$(openssl rand -base64 24)
echo "$passphrasse_subkeys" >> llaves_backup/passwd_subkeys.txt

#Genero entropía
sudo rngd -r /dev/urandom

#Reinicio el agente gpg
gpgconf --kill gpg-agent  # Required, if agent_genkey fail...
gpgconf --kill gpg-agent  # Required, if agent_genkey fail...

#Creo la llave privada
gpg --generate-key --batch <<eoGpgConf
    Key-Type: RSA
    Key-Length: 4096
    Name-Real: "$nombre"
    Name-Comment: Viva Cristo Rey
    Name-Email: "$email"
    Expire-Date: 9999-12-31
    Passphrase: $(<llaves_backup/passwd.txt)
    %commit
eoGpgConf

#Obtengo el id de la llave privada
keyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Exporto la llave privada
gpg --pinentry-mode loopback --passphrase "$(<llaves_backup/passwd.txt)" --output llaves_backup/privatekey.gpg --armor --export-secret-keys --export-options export-backup "$email"

#Exporto la llave pública
gpg --output llaves_backup/publickey.gpg --armor --export "$email"

#Envío la llave publica a un servidor publico
#gpg --keyserver keyserver.ubuntu.com --send-keys "$keyid"

#Obtengo la huella de la llave privada
FPR=$(gpg --list-options show-only-fpr-mbox --list-secret-keys | awk '{print $1}')

gpg --batch --passphrase '' \
    --quick-add-key $FPR RSA sign 100y
gpg --batch --passphrase '' \
    --quick-add-key $FPR RSA encrypt 100y
gpg --batch --passphrase '' \
    --quick-add-key $FPR RSA auth 100y


##########################
#Exporto las subclaves para importarlas a un nuevo directorio temporal, cambiar la passphrasse y finalmente exportar esas subclaves
##########################

# Crea un directorio temporal para el nuevo anillo de claves
tempdir2=$(mktemp -d)

# Exporta las subclaves
gpg --export-secret-subkeys "$keyid"! >llaves_backup/subkeys.pgp

# Importa las subclaves al nuevo anillo de claves
export GNUPGHOME=$tempdir2
gpg --import llaves_backup/subkeys.pgp

# Cambio la frase de contraseña de las subclaves
echo "$passphrasse_subkeys" | gpg --command-fd 0 --edit-key "$keyid"

# Exporto las subclaves
gpg --export-secret-subkeys "$keyid"! >llaves_backup/new_subkeys.pgp

# Elimina el directorio temporal y vuelve al directorio original
rm -rf $tempdir2

#Vuelvo al directorio gpg anterior
export GNUPGHOME=$tempdir
##########################
#Fin exportación de subclaves
##########################


#Paro la generación de entropía
pidrngd=$(pgrep rngd)
sudo kill -9 "$pidrngd"

#borro el directorio de gpg temporal y vuelvo a colocar el principal
unset GNUPGHOME
rm -r $tempdir
