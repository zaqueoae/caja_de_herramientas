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


#Paro la generación de entropía
pidrngd=$(pgrep rngd)
sudo kill -9 "$pidrngd"



echo ""
echo "Ahora voy a comprobar que todo va bien."
echo "Voy a probar que la llave publica descarga bien y es la que yo he importado."
echo "Voy a probar que firmo y verifico la firma correctamente."
echo "Voy a probar que encripto y desencripto correctamente."
echo "Voy a dejar las pruebas en la carpeta test_llaves/"
echo "Allá voy"
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
comprobacion_autenticidad_llave_publica "$passphrase" "$email" llaves_backup/subkey_sign.pgp

#Obtengo el id de la subkey de firma
subkeyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Firmo
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --local-user "$subkeyid" --output "${file_test}_sign.gpg" --sign "$file_test"

# Comprueba la firma
gpg --verify "$file_test"_sign.gpg
# Almacena el estado de salida del último comando ejecutado
compruebo=$?

if [ "$compruebo" -eq 0 ]; then
    echo "La verificación de la firma fue exitosa."
    sign_test=0
else
    echo "La verificación de la firma falló."
    exit
fi




#################
# Comprobación de la llave de cifrado
#################

# Creo un directorio temporal
tempdir5=$(mktemp -d)
# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir5"
comprobacion_autenticidad_llave_publica "$passphrase" "$email" llaves_backup/subkey_encrypt.pgp

#Obtengo el id de la subkey de cifrado
subkeyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Cifro
gpg --trust-model always --yes --output "${file_test}_encrypt.gpg" --encrypt --recipient "$email" "$file_test"

#Obtengo el id de la subkey de encriptado
subkeyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Desencripto
echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --local-user ${subkeyid} --output ${file_test}_decrypt.txt --decrypt ${file_test}_encrypt.gpg

#Compruebo que le desencriptado ha ido bien
filenoencrypt="$(<test_llaves/texto.txt)"
filedecrypt="$(<${file_test}_decrypt.txt)"

if [[ "$filenoencrypt" = "$filedecrypt" ]]; then
    echo "El encriptado y desencriptado SI ha funcionado."
    encrypt_test=0
else
    echo "El encriptado desencriptado NO ha funcionado."
    exit
fi



#########################################################
#PRUEBA 3: Autenticado
#########################################################
#No conozco una forma de testear una llave de authenticación offline. Pero si el test de firmado y de encriptado han ido bien, supondré que la subkey de autenticación es correcta.

#Conclusión
if [[ ("$encrypt_test" = 0 ) && ("$sign_test" = 0)]]; then
    echo "Veredicto final: He probado las llaves y todo va bien"
else
    echo "revisa el código, algo ha ido mal"
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

#Mato al fpf agent
gpgconf --kill gpg-agent 
#MAto los procesos de gpgagent
pkill gpg-agent
