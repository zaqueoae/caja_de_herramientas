#!/bin/bash

# Explanation:
#
# This script generates unattended with gpg a private key and 3 subkeys.
# The primary private key, public key and the 3 subkeys are exported to separate files. 
# This is not usual, since gpg "forces" all private keys to be exported together. To achieve this I had to use a "little trick".
# The passphrase is noted in 1 txt file.
# The public key is imported to a public server.
# To do all this I use temporary directories, so when I'm done there is no trace left. Only the exported files remain.

# Finally, I verify the authenticity of the public key by downloading it from the public server, sign and verify the signature, encrypt, decrypt and verify the decryption.


#######################################################
#gpg variables. Modify this
tag="Viva Cristo Rey"
lenghtkey="4096"
typekey="RSA"
expiregpg="9999-12-31"
#######################################################

############################
# Funciones
############################
# Funcion que comprueba si la llave publica descargada es autentica
# Ejemplo: comprobacion_autenticidad_llave_publica "$passphrase" "$email" llaves_backup/subkey_sign.pgp
comprobacion_autenticidad_llave_publica(){
    passphrase="$1"
    email="$2"
    path_llave_privada="$3"

    #Importo la subkey de firma
    echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import "$path_llave_privada"

    #Obtengo la huella de la subkey
    huella_privada=$(gpg --fingerprint --with-colons "$email" | awk -F: '/fpr/{print $10}' | tr -d ' ')

    #Me descargo la llave pública
    gpg --keyserver hkps://keyserver.ubuntu.com --with-colons --search-keys "$email"
    #gpg --keyserver keyserver.ubuntu.com --recv-keys "$email"

    #Saco la huella de la llave publica
    huella_publica=$(gpg --fingerprint --with-colons "$email" | awk -F: '/fpr/{print $10}' | tr -d ' ')

    # Compara las huellas digitales
    if [ ! "$huella_publica" = "$huella_privada" ]; then
        echo "La clave pública no es auténtica"
        exit
    fi
}
############################
# Fin Funciones
############################

PS3='Are you on an airgapped computer or a computer connected to the internet? Please enter your choice: '
options=("Airgapped" "Internet" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Airgapped")
            airgap=1
            break
            ;;
        "Internet")
            airgap=0
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

read -r -p "What is your name? " name
read -r -p "What is your email? " email

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

#Creo la llave privada
gpg --generate-key --batch <<eoGpgConf
    Key-Type: $typekey
    Key-Length: $lenghtkey
    Name-Real: $name
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

if [[ "$airgap" = 0 ]]; then
    #Envío la llave publica a un servidor publico
    gpg --keyserver keyserver.ubuntu.com --send-keys "$keyid"
fi




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


#Paro la generación de entropía
pidrngd=$(pgrep rngd)
sudo kill -9 "$pidrngd"



echo ""
echo "Now I'm going to check that everything is okay."
echo "I'm going to test that the public key downloads correctly and is the one I imported."
echo "I'm going to test that I sign and verify the signature correctly."
echo "I'm going to test that I encrypt and decrypt correctly."
echo "I'm going to leave the tests in the test_keys/ folder"
echo "There I go"
echo ""



#Creo una carpeta y un archivo para los test
rm -rf test_llaves
mkdir -p test_llaves
echo "Ave María Purísima" >> test_llaves/texto.txt
file_test="test_llaves/texto.txt"


#Reinicio el agente gpg
gpgconf --kill gpg-agent


#################
# Comprobación de la llave de firma
#################

# Creo un directorio temporal
tempdir4=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir4"

if [[ "$airgap" = 0 ]]; then
    comprobacion_autenticidad_llave_publica "$passphrase" "$email" llaves_backup/subkey_sign.pgp
else
    #Importo la llave publica desde el archivo
    gpg --import llaves_backup/publickey.gpg
    #Importo la subkey de firma
    echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/subkey_sign.pgp
fi

#Obtengo el id de la subkey de firma
subkeyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Firmo
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --local-user "$subkeyid" --output "${file_test}_sign.gpg" --sign "$file_test"

# Comprueba la firma
gpg --verify "$file_test"_sign.gpg
# Almacena el estado de salida del último comando ejecutado
compruebo=$?

if [ "$compruebo" -eq 0 ]; then
    echo "The signature verification was successful."
    sign_test=0
else
    echo "Signature verification FAILED."
    exit
fi


#################
# Comprobación de la llave de cifrado
#################

# Creo un directorio temporal
tempdir5=$(mktemp -d)
# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir5"

if [[ "$airgap" = 0 ]]; then
    comprobacion_autenticidad_llave_publica "$passphrase" "$email" llaves_backup/subkey_encrypt.pgp
else
    #Importo la llave publica desde el archivo
    gpg --import llaves_backup/publickey.gpg
    #Importo la subkey de firma
    echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/subkey_encrypt.pgp
fi

#Cifro
gpg --encrypt --recipient "$email" "$file_test"

#Desencripto
echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 --output decrypt_${file_test} --decrypt ${file_test}.gpg

#Compruebo que le desencriptado ha ido bien
filenoencrypt="$(<$file_test)"
filedecrypt="$(<decrypt_$file_test)"

if [[ "$filenoencrypt" = "$filedecrypt" ]]; then
    echo "The encryption and decryption YES has worked."
    encrypt_test=0
else
    echo "Decryption encryption has NOT worked."
    exit
fi


#Conclusión
if [[ ("$encrypt_test" = 0 ) && ("$sign_test" = 0)]]; then
    echo "Final verdict: I have tested the keys and everything is fine"
    echo "I have left the keys and the passphrase in /llaves_backup/"
    echo "Bye"
else
    echo "Check the code, something has gone wrong with the signing or encryption"
fi

#Me cargo las variables con contenido sensible
unset passphrase
unset FPR


#Borrado de anillos
unset GNUPGHOME
rm -r "$tempdir"
rm -r "$tempdir2"
rm -r "$tempdir3"
rm -r "$tempdir4"
rm -r "$tempdir5"

#Mato al gpg agent
gpgconf --kill gpg-agent 
#MAto los procesos de gpgagent
pkill gpg-agent
