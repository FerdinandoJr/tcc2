#!/bin/bash

source "ipcs_dict.sh"
declare -A dynamic_dict

# Variáveis
contador=0

# CONSTANTES
DIR_TEMP="dirTemp" # Nome da pasta temporaria
LIST_DEBIAN_PACKAGES="debian_packages.txt" #  Nome do arquivo que possui a lista de pacotes
LOGFILE="error_log.txt"
DATABASE="base.db3" # Defina o caminho do seu banco de dados SQLite

# Reseta o dicionario dinamico
resetDict(){
  dynamic_dict["pipe"]=0
  dynamic_dict["fifo"]=0
  dynamic_dict["socket"]=0
  dynamic_dict["pseudo_terminal"]=0
  dynamic_dict["sysv_message_queues"]=0
  dynamic_dict["posix_message_queues"]=0
  dynamic_dict["cross_memory_attach"]=0
  dynamic_dict["sysv_shared_memory"]=0
  dynamic_dict["posix_shared_memory"]=0
  dynamic_dict["mmap"]=0
  dynamic_dict["anonymous_memory_mapping"]=0
  dynamic_dict["sysv_semaphores"]=0
  dynamic_dict["posix_semaphores"]=0
  dynamic_dict["eventfd"]=0
  dynamic_dict["file_and_record_locks"]=0
  dynamic_dict["mutexes"]=0
  dynamic_dict["condition_variables"]=0
  dynamic_dict["barriers"]=0
  dynamic_dict["read_write_locks"]=0

  return 0
}

# Emite Erros do sistema
logError(){
  # Mensagem de erro
  errorMessage="$1"
  
  # Verifica se a mensagem veio foi fornecido
  if [ -z "$errorMessage" ]; then
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Erro desconhecido ocorreu." >> "$LOGFILE"
    return 1
  fi

  message="[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] $errorMessage"
  
  echo $message # Printa no console a mensagem
  echo $message >> "$LOGFILE" # Salva no arquivo de erro

  return 0
}

filterIPCs() {
  fileName="$1"
  content="$2"
  packageId="$3"
  

  # Reseta o dicionario
  resetDict

  # Caminho para o arquivo com as palavras-chave
  KEYWORDS_FILE="ipcs.txt"

  # Ler as palavras-chave e montar uma expressão regular com limites de palavra
  REGEX=$(awk '{print "\\b"$0"\\b"}' $KEYWORDS_FILE | tr '\n' '|' | sed 's/|$//')

  # Filtrar o texto e obter palavras únicas, armazenar na variável
  filtered_words=$(echo "$content" | grep -o -E "$REGEX" | sort | uniq)

  # Verifica cada item da lista no dicionário
  for item in $filtered_words; do    
    key=${func_dict[$item]}
    if [[ ${dynamic_dict[$key]} -eq 0 ]]; then
     dynamic_dict[$key]=1
    fi
  done

  path="${fileName#dirTemp/}"

  insert_query="INSERT INTO executable_files VALUES (null, $packageId, 1, '$path', ${dynamic_dict['pipe']}, ${dynamic_dict['fifo']}, ${dynamic_dict['socket']}, ${dynamic_dict['pseudo_terminal']}, ${dynamic_dict['sysv_message_queues']}, ${dynamic_dict['posix_message_queues']}, ${dynamic_dict['cross_memory_attach']}, ${dynamic_dict['sysv_shared_memory']}, ${dynamic_dict['posix_shared_memory']}, ${dynamic_dict['mmap']}, ${dynamic_dict['anonymous_memory_mapping']}, ${dynamic_dict['sysv_semaphores']}, ${dynamic_dict['posix_semaphores']}, ${dynamic_dict['eventfd']}, ${dynamic_dict['file_and_record_locks']}, ${dynamic_dict['mutexes']}, ${dynamic_dict['condition_variables']}, ${dynamic_dict['barriers']}, ${dynamic_dict['read_write_locks']});"

  #echo $insert_query

  sqlite3 $DATABASE "$insert_query"

  echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Finalizado filtragem de IPCs - $path"
  
}

# Processa os arquivos de um pacote .dev
processFiles() {
  fileList="$1"
  package_id="$2"
  packageName="$3"

  # Construindo a lista de arquivos executáveis
  execlist=$(for f in $fileList; do
    # Removendo os dois primeiros caracteres do caminho    
    f="$DIR_TEMP/${f:2}"

    if [ -f "$f" ] && [ -x "$f" ]; then
      echo "$f"
    fi
  done)
  
  # Processando cada arquivo executável
  for f in $execlist; do
    # Obtém a descrição completa do arquivo
    filedesc=$(file "$f")

    if echo "$filedesc" | grep -qi "ELF"; then
      # Para arquivos ELF, executa o objdump e processa adicionalmente
      output=$(objdump -R "$f" | grep "_JUMP_SLOT" | awk '{print $3}' | cut -d'@' -f1)
      # Verifica se objdump foi bem-sucedido
      if [ $? -eq 0 ]; then
        # Executa a função filterIPCs somente se objdump não deu erro
        filterIPCs "$f" "$output" "$package_id"
      else
        logError "objdump encontrou um erro processando o arquivo $f do pacote $package_name ($package_id)"
      fi
    else
      tipo=8
      if echo "$filedesc" | grep -qi "symbolic link"; then
        tipo=2
      elif echo "$filedesc" | grep -qi ".awk"; then
        tipo=3
      elif echo "$filedesc" | grep -qi "awk script"; then
        tipo=3
      elif echo "$filedesc" | grep -qi "perl script"; then
        tipo=4
      elif echo "$filedesc" | grep -qi "bourne-again shell script"; then
        tipo=5
      elif echo "$filedesc" | grep -qi "posix shell script"; then
        tipo=6
      elif echo "$filedesc" | grep -qi "python script"; then
        tipo=7
      else
        tipo=8
      fi

      path="${f#dirTemp/}"

      insert_query="INSERT INTO executable_files VALUES (null, $packageId, $tipo, '$path', false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false , false);"

      #echo $insert_query

      sqlite3 $DATABASE "$insert_query"

      echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Finalizado análise de arquivo - $path"
    fi
  done

  return 0
}

# Faz download do pacote e desempacota
downloadPackage() {
  # O nome do pacote é o primeiro argumento do script
  packageName="$1"

  #packageName="thunderbird" pacote teste

  # Verifica se o nome do pacote foi fornecido
  if [ -z "$packageName" ]; then
    logError "Erro: Nome do pacote não fornecido."
    return 1
  fi

  # Cria a pasta DIRTEMP se ela não existir
  mkdir -p "$DIR_TEMP"

  # Busca os nomes dos arquivos do pacote
  filesName=$(apt-cache show $packageName | grep "Filename" | cut -d ' ' -f 2)
  success=false

  # Tenta baixar cada arquivo
  for fn in $filesName; do
    url="http://ubuntu.c3sl.ufpr.br/ubuntu/$fn"
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Tentando baixar pacote... ($url)"
    # Faz download do pacote para a pasta DIR_TEMP
    if wget -P "$DIR_TEMP/" "$url"; then
      echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Download do pacote $packageName completado com sucesso."
      success=true
      break
    fi
  done

  # Verifica se o download foi bem-sucedido
  if [ "$success" = false ]; then
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Não foi possível baixar o pacote $packageName usando nenhuma das URLs disponíveis."

    datetime=$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')

    # Comando SQL para inserir um pacote .deb
    insert_pacote="INSERT INTO deb_package (name, download_date, download_url) VALUES ('$packageName', '$datetime', '');"

    # Executar comando SQL usando sqlite3 e pegar o ID do pacote inserido
    sqlite3 $DATABASE "$insert_pacote"

    return 1
  fi

  # Abre arquivo .deb no diretório dir
  deb=$(basename "$url")  

  # Desempacota o arquivo .deb"
  if ! output=$(dpkg-deb -X "$DIR_TEMP/$deb" "$DIR_TEMP"); then
    logError "Erro ao desempacotar $deb"
    return 1
  fi

  echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Pacote $deb desempacotado com sucesso."

  datetime=$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')

  # Comando SQL para inserir um pacote .deb
  insert_pacote="INSERT INTO deb_package (name, download_date, download_url) VALUES ('$packageName', '$datetime', '$url');"

  # Executar comando SQL usando sqlite3 e pegar o ID do pacote inserido
  package_id=$(sqlite3 $DATABASE "$insert_pacote; SELECT last_insert_rowid();")

  processFiles "$output" "$package_id" "$packageName"

  return 0
}

start() {
  # O primeiro argumento é o número da linha de início
  local inicio=${1:-1}  # Usa 1 como padrão se nenhum número for fornecidofile:///home/ferdinando-galera/Projects/download-full-packges-debian/download_package.sh
  
  local total_linhas=$(wc -l < "$LIST_DEBIAN_PACKAGES")
  local fim=${2:-$total_linhas}  # Usa o total de linhas como padrão se nenhum número for fornecido
  
  touch $LOGFILE # Cria o arquivo para logs de erros
  rm -rf "$DIR_TEMP" # Remove a pasta DIR_TEMP se ela existir
  echo "" > "typefile.txt"
  
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
    echo ""
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Pacote $contador - $linha"
    downloadPackage "$linha" || echo "Erro ao processar $linha"

    # Limpa o terminal
    #clear
    
    # Incrementa o contador
    ((contador++))
    
    # # Sai do loop após ler 15 linhas
    # if [ $contador -eq 1000 ]; then
    #   break
    # fi
  done

  sort typefile.txt | uniq > typefile_uniq.txt

}

# Chama a função start com o número da linha como argumento
start "$1" "$2"
