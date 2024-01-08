#!/bin/bash

NODO="$1"

# Set Color
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"

github-authenticated() {
    # Attempt to ssh to GitHub
    ssh -T "$1" &>/dev/null
    RET=$?
    if [ $RET == 1 ]; then
    return 0
    elif [ $RET == 255 ]; then
    return 1
    else
    echo "unknown exit code in attempt to ssh into git@github.com"
    fi
    return 2
}

config_ssh () {
    mkdir -p ~/.ssh
    rm -f ~/.ssh/config
    touch ~/.ssh/config
    
    echo 'StrictHostKeyChecking no' >> ~/.ssh/config
    echo 'XAuthLocation /opt/X11/bin/xauth' >> ~/.ssh/config
    echo 'ForwardAgent yes' >> ~/.ssh/config
    
    echo 'Include github' >> ~/.ssh/config
    
    echo 'Host *' >> ~/.ssh/config
    echo 'IdentitiesOnly=yes' >> ~/.ssh/config
    echo 'PreferredAuthentications=publickey' >> ~/.ssh/config
}


conexion_shh_github_bash_catinfog () {
    if ! (github-authenticated githubssh); then
        mkdir -p ~/.ssh/local
        rm -f ~/.ssh/local/id_rsagithub
        ssh-keygen -b 4096 -t rsa -f ~/.ssh/local/id_rsagithub -q -N ""
        chmod 400 ~/.ssh/local/id_rsagithub
        chmod 644 ~/.ssh/local/id_rsagithub.pub
        
        
        
        #Añado las llaves a ssh agent
        eval "$(ssh-agent)"
        ssh-add ~/.ssh/local/id_rsagithub
        pub=$(cat ~/.ssh/local/id_rsagithub.pub)
        echo ''
        echo ''
        for (( ; ; ))
        do
            githubuser=0
            githubpass=0
            read -r -p "Escribe tu usuario de github para conectar con el repo de Bash Catinfog: " githubuser
            echo "Tu usuario de github es $githubuser"
            echo ''
            read -r -p "Escribe la api-key de $githubuser: " -s githubpass
            echo ''
            curl -u "$githubuser:$githubpass" -X POST -d "{\"title\":\"`hostname`\",\"key\":\"$pub\"}" https://api.github.com/user/keys
            
            sed -i "/#$githubuser/,/#$githubuser/d" ~/.ssh/github
            echo '' >> ~/.ssh/github
            echo "#$githubuser" >> ~/.ssh/github
            echo 'Host githubssh' >> ~/.ssh/github
            echo '        User git' >> ~/.ssh/github
            echo '        HostName github.com' >> ~/.ssh/github
            echo '        IdentityFile ~/.ssh/local/id_rsagithub' >> ~/.ssh/github
            echo "#$githubuser" >> ~/.ssh/github
            echo '' >> ~/.ssh/github
            
            if github-authenticated githubssh; then
                echo "Hemos conectado"
                break
            else
                echo "Algo ha fallado: el nombre de usuario o el api token."
                echo "Aquí tienes un manual para crear un api token: https://docs.github.com/es/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens"
                read -n 1 -s -r -p "Pulsa Enter para volver a intentar conectar"
                echo ''
            fi
        done
    fi
}

clonacion_bash_catinfog () {
rm -rf ~/bashcatinfog
rm -rf ~/bash

git clone githubssh:zaqueoae/bashcatinfog.git ~/bashcatinfog

}

execute_bash () {
  bash ~/bashcatinfog/ini.sh "$NODO"
}

printf "\n${BLUE}======================== Creando los archivos config ssh ========================${ENDCOLOR}\n"
config_ssh
printf "${GREEN}======================== ¡Archivos config ssh creados! ========================${ENDCOLOR}\n"

printf "\n${BLUE}======================== Creando conexión con Github ========================${ENDCOLOR}\n"
conexion_shh_github_bash_catinfog
printf "${GREEN}======================== ¡Conexión con Github creada! ========================${ENDCOLOR}\n"

printf "\n${BLUE}======================== Clonando archivos bash catinfog ========================${ENDCOLOR}\n"
clonacion_bash_catinfog
printf "${GREEN}======================== ¡Clonados los archivos bash catinfog! ========================${ENDCOLOR}\n"

printf "\n${BLUE}======================== Ejecutanto la caja de herramientas ========================${ENDCOLOR}\n"
execute_bash
