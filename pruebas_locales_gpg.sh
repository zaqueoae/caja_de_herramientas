#!/bin/bash

#gpg variables. Modify this
email="info@pacopepe3242335.com"

#Obtengo la passphrase
passphrase="$(<llaves_backup/passwd.txt)"

#Creo una carpeta y un archivo para los test
rm -rf test_llaves
mkdir -p test_llaves
echo "Ave María Purísima" >> test_llaves/texto.txt

#Reinicio el agente gpg
gpgconf --kill gpg-agent


#########################################################
#PRUEBA 1: Firma
#########################################################
# Creo un directorio temporal
tempdir4=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir4"

#Me descargo la llave pública
gpg --keyserver keyserver.ubuntu.com --recv-keys "$email"

#Importo la subkey de firma
gpg --import llaves_backup/subkey_sign.pgp

#Obtengo el id de la subkey de firma
subkeyid=$(gpg --list-secret-keys "$email" | awk '/ssb/{print $2}' | cut -d'/' -f2)

#Firmo
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --local-user "$subkeyid" --output "${file_test}_sign.gpg" --sign "$file_test"

# Comprueba la firma
gpg --verify "$file_test"_sign.gpg
# Almacena el estado de salida del último comando ejecutado
compruebo=$?

if [ "$compruebo" -eq 0 ]; then
    echo "La verificación de la firma fue exitosa."
else
    echo "La verificación de la firma falló."
fi

#########################################################
#PRUEBA 2: Encriptado Desencriptado
#########################################################
# Creo un directorio temporal
tempdir5=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir5"

#Me descargo la llave pública

#Importo la subkey de encriptado

#Encripto

#Desencripto

#Compruebo que le desencriptado ha ido bien


#########################################################
#PRUEBA 3: Autenticado
#########################################################
# Creo un directorio temporal
tempdir5=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir5"

#Me descargo la llave pública

#Importo la subkey de autenticado

#Firmo

#Comprueno la firma


#Conclusión

#Borrado de anillos
