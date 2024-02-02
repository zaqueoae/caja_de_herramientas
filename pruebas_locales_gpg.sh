#!/bin/bash

#gpg variables. Modify this
email="info@pacopepe3242335.com"


#Reinicio el agente gpg
gpgconf --kill gpg-agent

#Creo una carpeta y un archivo para los test
rm -rf test-llaves
mkdir -p test-llaves
echo "Ave María Purísima" >> 


#PRUEBA 1: Firma
# Creo un directorio temporal
tempdir4=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir4

#Me descargo la llave pública

#Importo la subkey de firma

#Firmo

#Comprueno la firma


#PRUEBA 2: Encriptado Desencriptado
tempdir5=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir5

#Me descargo la llave pública

#Importo la subkey de encriptado

#Encripto

#Desencripto

#Compruebo que le desencriptado ha ido bien


#PRUEBA 3: Autenticado
tempdir5=$(mktemp -d)

# Configuo GNUPGHOME para apuntar al directorio temporal
export GNUPGHOME=$tempdir5

#Me descargo la llave pública

#Importo la subkey de autenticado

#Firmo

#Comprueno la firma


#Conclusión

#Borrado de anillos
