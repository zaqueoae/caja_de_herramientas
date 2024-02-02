#!/bin/bash

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

    #Borro la subkey
    gpg --delete-secret-keys "$email"

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


#Mato al fpf agent
gpgconf --kill gpg-agent 
#MAto los procesos de gpgagent
pkill gpg-agent


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


#################
# Comprobación de la llave de firma
#################

# Creo un directorio temporal
tempdir4=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME="$tempdir4"
comprobacion_autenticidad_llave_publica "$passphrase" "$email" llaves_backup/subkey_sign.pgp

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

#Importo de nuevo la subkey de cifrado
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import llaves_backup/subkey_encrypt.pgp

#Obtengo el id de la subkey de cifrado
subkeyid=$(gpg --list-keys --keyid-format SHORT "$email" | grep pub | cut -d'/' -f2 | cut -d' ' -f1)

#Cifro
gpg --yes --output "${file_test}_encrypt.gpg" --encrypt --recipient "$email" "$file_test"

#Obtengo el id de la subkey de encriptado
subkeyid=$(gpg --list-secret-keys "$email" | awk '/ssb/{print $2}' | cut -d'/' -f2)

#Desencripto
echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --local-user "$subkeyid" --output "${file_test}_encrypt.gpg" --decrypt "$file_test"_decrypt.txt

#Compruebo que le desencriptado ha ido bien
filenoencrypt="$(<test_llaves/texto.txt)"
filedecrypt="$(<$file_test_decrypt.txt)"

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


#Borrado de anillos
unset GNUPGHOME
rm -r "$tempdir4"
rm -r "$tempdir5"

#Mato al fpf agent
gpgconf --kill gpg-agent 
#MAto los procesos de gpgagent
pkill gpg-agent

