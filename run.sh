#!/bin/bash

# Variáveis
contador=0

# CONSTANTES
DIR_TEMP="dirTemp" # Nome da pasta temporaria
LIST_DEBIAN_PACKAGES="debian_packages.txt" #  Nome do arquivo que possui a lista de pacotes
LOGFILE="error_log.txt"

# Emite Erros do sistema
logError(){
  # Mensagem de erro
  errorMessage="$1"
  
  # Verifica se a mensagem veio foi fornecido
  if [ -z "$errorMessage" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Erro desconhecido ocorreu." >> "$LOGFILE"
    return 1
  fi

  message="[$(date '+%Y-%m-%d %H:%M:%S')] $errorMessage"
  
  echo $message # Printa no console a mensagem
  echo $message >> "$LOGFILE" # Salva no arquivo de erro

  return 0
}

# Processa os arquivos de um pacote .dev
processFiles() {
  fileList="$1"

  # Construindo a lista de arquivos executáveis
  execlist=$(for f in $fileList; do
    # Removendo os dois primeiros caracteres do caminho    
    f="$DIR_TEMP/${f:2}"
    echo 
    if [ -f "$f" ] && [ -x "$f" ]; then
      echo "$f"
    fi
  done)

  #Processando cada arquivo executável
  for f in $execlist; do
    echo $f
    output=$(objdump -R "$f" 2>/dev/null | grep "_JUMP_SLOT" | awk '{print $3}' | cut -d'@' -f1)
  done
  

}

# Faz download do pacote e desempacota
downloadPackage() {
  # O nome do pacote é o primeiro argumento do script
  packageName="$1"

  packageName="thunderbird"

  # Verifica se o nome do pacote foi fornecido
  if [ -z "$packageName" ]; then
    logError "Erro: Nome do pacote não fornecido."
    return 1
  fi

  # Pega a url do pacote
  url=$(apt-cache show "$packageName" 2>/dev/null | awk '/^Filename:/ {print "http://ubuntu.c3sl.ufpr.br/ubuntu/"$2; exit}')

  # Cria a pasta DIRTEMP
  mkdir $DIR_TEMP

 # Faz download do pacote para a pasta DIR_TEMP
  if ! wget -P "$DIR_TEMP/" "$url"; then    
    logError "Erro ao baixar o pacote $packageName"
    return 1
  fi

  echo "Download do pacote $packageName completado com sucesso."

  # Abre arquivo .deb no diretório dir
  deb=$(basename "$url")
  
  # Desempacota o arquivo .deb"
  #flist=$(dpkg -X "$DIR_TEMP/$deb" "$DIR_TEMP") 
  if ! output=$(dpkg -X "$DIR_TEMP/$deb" "$DIR_TEMP"); then
    logError "Erro ao desempacotar $deb"
    return 1
  fi

  echo "Pacote $deb desempacotado com sucesso."

  processFiles "$output"

  return 0
}

start() {
  # O primeiro argumento é o número da linha de início
  local inicio=${1:-1}  # Usa 1 como padrão se nenhum número for fornecidofile:///home/ferdinando-galera/Projects/download-full-packges-debian/download_package.sh
  
  local total_linhas=$(wc -l < "$LIST_DEBIAN_PACKAGES")
  local fim=${2:-$total_linhas}  # Usa o total de linhas como padrão se nenhum número for fornecido
  

  touch $LOGFILE # Cria o arquivo para logs de erros
  rm -rf "$DIR_TEMP" # Remove a pasta DIR_TEMP se ela existir

  # Verifica se o arquivo existe
  if [ ! -f "$LIST_DEBIAN_PACKAGES" ]; then
    echo "Erro: O arquivo '$LIST_DEBIAN_PACKAGES' não existe."
    exit 2
  fi
 
  # Verifica se o início é um número inteiro positivo
  if ! [[ $inicio =~ ^[0-9]+$ ]]; then
    echo "Erro: O argumento fornecido ('$inicio') não é um número válido."
    exit 3
  fi


  # e read dentro de um loop while para ler cada linha
  #tail -n +$inicio "$nome_do_arquivo" | while IFS= read -r linha; do
  sed -n "${inicio},${fim}p" "$LIST_DEBIAN_PACKAGES" | while IFS= read -r linha; do
  
    #echo "$linha"
    # Faz o Download e Desempacota o pacote
    downloadPackage "$linha" || echo "Erro ao processar $linha"

    # Incrementa o contador
    ((contador++))
    
    # Sai do loop após ler 15 linhas
    if [ $contador -eq 1 ]; then
      break
    fi
  done
}

# Chama a função start com o número da linha como argumento
start "$1" "$2"

