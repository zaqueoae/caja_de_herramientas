#!/bin/bash

unset GNUPGHOME
rm -rf "$tempdir4"
rm -rf "$tempdir5"

#gpg variables. Modify this
email="info@pacopepe3242335.com"

#Obtengo la passphrase
passphrase="$(<llaves_backup/passwd.txt)"

#Creo una carpeta y un archivo para los test
rm -rf test_llaves
mkdir -p test_llaves
echo "Ave María Purísima" >> test_llaves/texto.txt
file_test="test_llaves/texto.txt"


#Reinicio el agente gpg
gpgconf --kill gpg-agent


#########################################################
#PRUEBA 1: Firma
#########################################################
# Creo un directorio temporal
tempdir4=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir4"

#Importo la subkey de firma
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/subkey_sign.pgp

#Saco la huella de la subkey
huella_privada=$(gpg --fingerprint --with-colons "$email" | awk -F: '/fpr/{print $10}' | tr -d ' ')

#Borro la subkey
gpg --delete-secret-keys "$email"

#Me descargo la llave pública
gpg --keyserver keyserver.ubuntu.com --recv-keys "$email"
#gpg --keyserver hkps://keyserver.ubuntu.com --with-colons --search-keys "$email"

#Saco la huella de la llave publica
huella_publica=$(gpg --fingerprint --with-colons "$email" | awk -F: '/fpr/{print $10}' | tr -d ' ')

# Compara las huellas digitales
if [ ! "$huella_publica" = "$huella_privada" ]; then
    echo "La clave pública no es auténtica"
    exit
else
    echo "La llave publica es auténtica"
fi

#Importo de nuevo la subkey de firma
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/subkey_sign.pgp

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
    sign_test=1
fi

#########################################################
#PRUEBA 2: Encriptado Desencriptado
#########################################################
# Creo un directorio temporal
tempdir5=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir5"

#Me descargo la llave pública
gpg --keyserver keyserver.ubuntu.com --trust-model always --recv-keys "$email"

#Obtengo el id la llave publica
publickeyid=$(gpg --list-keys "$email" | awk '/pub/{print $2}' | awk -F'/' '{print $2}')

# Obtengo la huella digital de la clave pública
public_key_fingerprint=$(gpg --fingerprint "$publickeyid" | grep -i fingerprint | awk '{print $2 $3 $4 $5 $6}')

#Importo la subkey de encriptado
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/subkey_encrypt.pgp

#Obtengo la huella digital de la subkey
subkey_fingerprint=$(gpg --list-keys --with-subkey-fingerprint "$email" | awk '/sub/{getline; print}' | tail -1 | sed 's/ //g')

# Compara las huellas digitales
if [ ! "$public_key_fingerprint" = "$subkey_fingerprint" ]; then
    echo "La clave pública no es auténtica"
    exit
fi

#Encripto
gpg --yes --output "${file_test}_encrypt.gpg" --encrypt --recipient "$email" "$file_test"

#Obtengo el id de la subkey de encriptado
subkeyid=$(gpg --list-secret-keys "$email" | awk '/ssb/{print $2}' | cut -d'/' -f2)

#Desencripto
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --local-user "$subkeyid" --output "${file_test}_encrypt.gpg" --decrypt "$file_test"_decrypt.txt

#Compruebo que le desencriptado ha ido bien
filenoencrypt="$(<test_llaves/texto.txt)"
filedecrypt="$file_test"_decrypt.txt

if [[ "$filenoencrypt" = "$filedecrypt" ]]; then
    echo "El encriptado desencriptado ha funcionado."
    encrypt_test=0
else
    echo "El encriptado desencriptado NO funcionado."
    encrypt_test=1
fi


#########################################################
#PRUEBA 3: Autenticado
#########################################################
# Creo un directorio temporal
#No conozco una forma de testear una llave de authenticación offline. Pero si el test de firmado y de encriptado han ido bien, supondré que la subkey de autenticación es correcta.

#Conclusión
if [[ ("$encrypt_test" = 0 ) && ("$sign_test" = 0)]]; then
    echo "Veredicto final: He probado las llaves y todo va bien"
else
    echo "revisa el código, algo ha ido mal"
fi


#Borrado de anillos
unset GNUPGHOME
rm -r "$tempdir4"
rm -r "$tempdir5"
