#!/bin/bash

SWAP="$1"

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
    mkdir -p .ssh
    rm -f .ssh/config
    touch .ssh/config
    if  [[ ! (-s  .ssh/backup)  ]]
    then 
        touch .ssh/backup
    fi
    if  [[ ! (-s  .ssh/github)  ]]
    then 
        touch .ssh/github
    fi
    if  [[ "$SWAP" = "swap" ]] && [[ ! (-s  .ssh/swappro)  ]]
    then 
        touch .ssh/swappro
    fi
    
    if  [[ "$SWAP" = "swap" ]] && [[ ! (-s  .ssh/swaptest)  ]]
    then 
        touch .ssh/swaptest
    fi
    
    echo 'StrictHostKeyChecking no' >> ~/.ssh/config
    echo 'XAuthLocation /opt/X11/bin/xauth' >> ~/.ssh/config
    echo 'ForwardAgent yes' >> ~/.ssh/config
    
    echo 'Include backup' >> ~/.ssh/config
    echo 'Include github' >> ~/.ssh/config
    
    if  [[ "$SWAP" = "swap" ]]
    then 
        echo 'Include swappro' >> ~/.ssh/config
        echo 'Include swaptest' >> ~/.ssh/config
    fi
    
    echo 'Host *' >> ~/.ssh/config
    echo 'IdentitiesOnly=yes' >> ~/.ssh/config
    echo 'PreferredAuthentications=publickey' >> ~/.ssh/config
}


conexion_shh_github_bash_catinfog () {
    if ! (github-authenticated githubssh); then
      ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsagithub -q -N ""
      chmod 400 ~/.ssh/id_rsagithub
      chmod 644 ~/.ssh/id_rsagithub.pub
      
      rm -f ~/.ssh/github
      touch ~/.ssh/github
      echo ''
      echo 'Host githubssh' >> ~/.ssh/github
      echo '        User git' >> ~/.ssh/github
      echo '        HostName github.com' >> ~/.ssh/github
      echo '        IdentityFile ~/.ssh/id_rsagithub' >> ~/.ssh/github
      
      #Añado las llaves a ssh agent
      eval "$(ssh-agent)"
      ssh-add ~/.ssh/id_rsagithub
      pub=$(cat ~/.ssh/id_rsagithub.pub)
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

conexion_shh_github_swap () {
    if ! (github-authenticated swap); then
      ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_swap -q -N ""
      chmod 400 ~/.ssh/id_swap
      chmod 644 ~/.ssh/id_swap.pub
      
      rm -f ~/.ssh/github
      touch ~/.ssh/github
      echo ''
      echo 'Host swap' >> ~/.ssh/github
      echo '        User git' >> ~/.ssh/github
      echo '        HostName github.com' >> ~/.ssh/github
      echo '        IdentityFile ~/.ssh/id_swap' >> ~/.ssh/github
      
      #Añado las llaves a ssh agent
      eval "$(ssh-agent)"
      ssh-add ~/.ssh/id_swap
      pub=$(cat ~/.ssh/id_rsagithub.pub)
      echo ''
      echo ''
      for (( ; ; ))
      do
          githubuser=0
          githubpass=0
          read -r -p "Escribe tu usuario de github pra conectar con el repo de SWAP: " githubuser
          echo "Tu usuario de github es $githubuser"
          echo ''
          read -r -p "Escribe la api-key de $githubuser: " -s githubpass
          echo ''
          curl -u "$githubuser:$githubpass" -X POST -d "{\"title\":\"`hostname`\",\"key\":\"$pub\"}" https://api.github.com/user/keys
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
rm -rf ~/swap
rm -rf ~/bash
mkdir -p ~/swap
mkdir -p ~/swap/bash
mkdir -p ~/bash
if [[ "$SWAP" = "swap" ]]
then
mkdir -p ~/swap/ssh
mkdir -p ~/swap/hash
mkdir -p ~/gitconfig
mkdir -p ~/hash
fi

git clone githubssh:zaqueoae/bashcatinfog.git ~/swap/bash
cp -rfp ~/swap/bash/0-Caja_de_herramientas/* ~/bash/

if [[ "$SWAP" = "swap" ]]
then
    git clone swap:patcatinside/ssh.git ~/swap/ssh
    cp -rfp ~/swap/ssh/* ~/gitconfig/
    git clone swap:patcatinside/hash.git ~/swap/hash
    cp -rfp ~/swap/hash/* ~/hash/
fi

rm -rf ~/swap
}

execute_bash () {
if [[ "$SWAP" = "swap" ]]
then
    bash ~/bash/tools.sh
fi
}

printf "\n${BLUE}======================== Creando los archivos config ssh ========================${ENDCOLOR}\n"
config_ssh
printf "${GREEN}======================== ¡Archivos config ssh creados! ========================${ENDCOLOR}\n"

printf "\n${BLUE}======================== Creando conexión con Github ========================${ENDCOLOR}\n"
conexion_shh_github_bash_catinfog
conexion_shh_github_swap
printf "${GREEN}======================== ¡Conexión con Github creada! ========================${ENDCOLOR}\n"

printf "\n${BLUE}======================== Clonando archivos bash catinfog ========================${ENDCOLOR}\n"
clonacion_bash_catinfog
printf "${GREEN}======================== ¡Clonados los archivos bash catinfog! ========================${ENDCOLOR}\n"

printf "\n${BLUE}======================== Ejecutanto la caja de herramientas ========================${ENDCOLOR}\n"
bash ~/bash/tools.sh
