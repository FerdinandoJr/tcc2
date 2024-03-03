#!/bin/bash

# Variáveis
nome_do_arquivo="debian_packages.txt"
contador=0

DIRTEMP="dirTemp"

downloadPackage() {
  # O nome do pacote é o primeiro argumento do script
  packageName="$1"

  # Verifica se o nome do pacote foi fornecido
  if [ -z "$packageName" ]; then
    echo "Erro: Nome do pacote não fornecido."
    exit 1
  fi

  # Pega a url do pacote
  url=$(apt-cache show $packageName | awk '/^Filename:/ {print "http://ubuntu.c3sl.ufpr.br/ubuntu/"$2; exit}')

  #echo $url

  # Cria a pasta DIRTEMP
  mkdir $DIRTEMP

  # Faz download do pacote para a pasta DIRTEMP
  wget -P "$DIRTEMP/" $url 

  # rm -r $DIRTEMP

}

start() {
  # O primeiro argumento é o número da linha de início
  local inicio=${1:-1}  # Usa 1 como padrão se nenhum número for fornecidofile:///home/ferdinando-galera/Projects/download-full-packges-debian/download_package.sh
  
  local total_linhas=$(wc -l < "$nome_do_arquivo")
  local fim=${2:-$total_linhas}  # Usa o total de linhas como padrão se nenhum número for fornecido
  
  # Verifica se o arquivo existe
  if [ ! -f "$nome_do_arquivo" ]; then
    echo "Erro: O arquivo '$nome_do_arquivo' não existe."
    exit 2
  fi
 
  # Verifica se o início é um número inteiro positivo
  if ! [[ $inicio =~ ^[0-9]+$ ]]; then
    echo "Erro: O argumento fornecido ('$inicio') não é um número válido."
    exit 3
  fi


  # e read dentro de um loop while para ler cada linha
  #tail -n +$inicio "$nome_do_arquivo" | while IFS= read -r linha; do
  sed -n "${inicio},${fim}p" "$nome_do_arquivo" | while IFS= read -r linha; do
  
    #echo "$linha"
    # Faz o Download do pacote
    downloadPackage "$linha"

    # Incrementa o contador
    ((contador++))
    
    # Sai do loop após ler 15 linhas
    if [ $contador -eq 15 ]; then
      break
    fi
  done
}

# Chama a função start com o número da linha como argumento
start "$1" "$2"

