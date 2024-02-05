#!/bin/bash

#Ejemplo de uso: gpg_importar_llave_publica mitia@g.com  bashcatinfog/llaves/llave_publica.pub bashcatinfog/llaves/subkey_sign.pgp
gpg_importar_llave_publica_desde_archivo () {

email="$1"
path_public_key="$2"
path_private_key="$3"

# Importa la clave principal y sus subclaves
gpg --import "$path_public_key"

# Obtén la huella digital de la clave principal
fingerprint=$(gpg --with-colons --fingerprint "$email" | awk -F: '/fpr/ {print $10}')

# Crea el archivo de confianza
echo "${fingerprint}:6:" | gpg --import-ownertrust
}


gpg_importar_llave_privada_desde_archivo(){
# Pregunta por la passphrase de la subkey de firma
read -r -s -p "Escribe la passphrase de la subkey de firma: " passphrase

#Importo la subkey de firma
echo $passphrase | gpg --batch --yes --passphrase-fd 0 --import "$path_private_key"
}



#Ejemplo de uso: comprime_firma_encripta /root/backup backup mitia@g.com
comprime_firma_encripta_backup(){
folder="$1"
file="$2"
email="$3"
# Comprime la carpeta
tar -czf "$file".tar.gz "$folder"

# Encripta y firma el archivo
gpg --recipient "$email" --local-user "$email" --output "$file".tar.gz.gpg --encrypt --sign "$file".tar.gz

#Dejo el archivo en la carpeta del usuriao orquestador para que se la descargue el bastion
cp "$file".tar.gz.gpg /home/orquestador/
chown orquestador:orquestador /home/orquestador/"$file".tar.gz.gpg

#Borro el directorio y el comprimido
rm -rf "$folder"
rm -f "$file".tar.gz
}
