#!/bin/bash

source "ipcs_dict.sh"
declare -A dynamic_dict

# Variáveis
contador=0

# CONSTANTES
DIR_FULL="$(pwd)"
DIR_PACKAGES="packages"
DIR_TEMP="dirTemp" # Nome da pasta temporaria
LIST_DEBIAN_PACKAGES="debian_packages.txt" #  Nome do arquivo que possui a lista de pacotes
LOGFILE="error_log.txt"
DATABASE="base.db3" # Defina o caminho do seu banco de dados SQLite
LIB_DIRS=( # Lista de caminhos de biblioteca
  "/usr/local/lib"
  "/lib/x86_64-linux-gnu"
  "/usr/lib/x86_64-linux-gnu"
  "/lib"
  "/usr/lib"
)
EXE_DIRS=( 
  "/bin"
  "/sbin"
  "/usr/bin"
  "/usr/sbin"
)


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
  tipo="$4"
  
  # Reseta o dicionario
  resetDict

  # Caminho para o arquivo com as palavras-chave
  KEYWORDS_FILE="ipcs.txt"

  # Ler as palavras-chave e montar uma expressão regular com limites de palavra
  REGEX=$(awk '{print "\\b"$0"\\b"}' $KEYWORDS_FILE | tr '\n' '|' | sed 's/|$//')

  # Filtrar o texto e obter palavras únicas, armazenar na variável
  filtered_words=$(echo "$content" | grep -o -E "$REGEX" | sort | uniq)

  # Verifica cada item da lista no dicionário
  veri=false
  for item in $filtered_words; do    
    key=${func_dict[$item]}
    if [[ ${dynamic_dict[$key]} -eq 0 ]]; then
     dynamic_dict[$key]=1
     veri=true
    fi
  done

  path="${fileName#dirTemp/}"

  insert_query="INSERT INTO executable_files VALUES (null, $packageId, $tipo, '$path', ${dynamic_dict['pipe']}, ${dynamic_dict['fifo']}, ${dynamic_dict['socket']}, ${dynamic_dict['pseudo_terminal']}, ${dynamic_dict['sysv_message_queues']}, ${dynamic_dict['posix_message_queues']}, ${dynamic_dict['cross_memory_attach']}, ${dynamic_dict['sysv_shared_memory']}, ${dynamic_dict['posix_shared_memory']}, ${dynamic_dict['mmap']}, ${dynamic_dict['sysv_semaphores']}, ${dynamic_dict['posix_semaphores']}, ${dynamic_dict['eventfd']}, ${dynamic_dict['file_and_record_locks']}, ${dynamic_dict['mutexes']}, ${dynamic_dict['condition_variables']}, ${dynamic_dict['barriers']}, ${dynamic_dict['read_write_locks']});"

  #echo $insert_query

  sqlite3 $DATABASE "$insert_query"

  if [ "$veri" = true ]; then
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] IPCs encontrados: $path"
  fi
  
}

# Função para verificar se o caminho está na lista de diretórios expecificos
checkExePath() {
  local path="$1"
  
  for dir in "${EXE_DIRS[@]}"; do
    if [[ "$path" == "$dir"* ]]; then
      return 0
    fi
  done
  
  return 1
}

# Função para verificar se o caminho está na lista de diretórios de biblioteca
checkLibraryPath() {
  local path="$1"
  
  for dir in "${LIB_DIRS[@]}"; do
    if [[ "$path" == "$dir"* ]]; then
      return 0
    fi
  done
  
  return 1
}


createRegisterFile() {
  package_id="$1"
  fileType="$2"
  filePath="$3"

  if echo "$fileType" | grep -qi 'ELF.*static'; then
    typeId=3
  elif echo "$fileType" | grep -qi "posix shell script"; then
    typeId=4  
  elif echo "$fileType" | grep -qi "python script"; then
    typeId=5
  elif echo "$fileType" | grep -qi "perl script"; then
    typeId=6
  elif echo "$fileType" | grep -qi "bourne-again shell script"; then
    typeId=7
  elif echo "$fileType" | grep -qi ".awk"; then
    typeId=8
  elif echo "$fileType" | grep -qi "awk script"; then
    typeId=8    
  else 
    # ARQUIVOS QUE NAO É IMPORTANTE REGISTRAR
    # echo "$package_id) $filePath: $fileType" >> "isNotElf.txt"
    return 1
  fi
  
  path="${filePath#dirTemp/}"
  insert_query="INSERT INTO executable_files VALUES (null, $package_id, $typeId, '$path', false ,false ,false ,false ,false ,false ,false ,false ,false ,false ,false,false ,false ,false ,false ,false ,false , false);"

  sqlite3 $DATABASE "$insert_query"
  
  echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Finalizado - $path"
  
  return 0
}

# Processa os arquivos de um pacote .dev
processFiles() {
  fileList="$1"
  package_id="$2"
  packageName="$3"

  #LibDirs=$(ldconfig -p | tail -n +2 | grep -o '/.*/' | sort -u)

  for f in $fileList; do
    # Remove os dois primeiros caracteres do caminho e ajusta para o diretório temporário
    file="/${f:2}"
    fileWithDirTemp="$DIR_TEMP/${f:2}"
    #echo "PATH-FULL: $f"

    # Verifica se o arquivo não é um link simbólico ou um diretorio
    if [[ -L "$fileWithDirTemp" || -d "$fileWithDirTemp" ]]; then
      continue
    fi

    filedesc=$(file -b "$fileWithDirTemp")    

    if [[ -f $fileWithDirTemp ]]; then
      if checkLibraryPath "$file" && [[ "$file" == *.so || "$file" == *.so.* ]]; then
        if echo "$filedesc" | grep -qi 'ELF.*dynamically'; then
          # PROCESSA IPC (BIBLIOTECA)
          output=$(objdump -R "$fileWithDirTemp" | grep -e "_JUMP_SLOT" -e "_GLOB_DAT" | awk '{print $3}' | cut -d'@' -f1)
          filterIPCs "$fileWithDirTemp" "$output" "$package_id" "2"  
        elif [ -x "$fileWithDirTemp" ]; then
          createRegisterFile "$package_id" "$filedesc" "$fileWithDirTemp"          
        fi
      elif checkLibraryPath "$file" || checkExePath "$file"; then   
        if [ -x "$fileWithDirTemp" ]; then
          if echo "$filedesc" | grep -qi 'ELF.*dynamically'; then
            # PROCESSA IPC (EXE)
            output=$(objdump -R "$fileWithDirTemp" | grep -e "_JUMP_SLOT" -e "_GLOB_DAT" | awk '{print $3}' | cut -d'@' -f1)
            filterIPCs "$fileWithDirTemp" "$output" "$package_id" "1" 
          else 
            createRegisterFile "$package_id" "$filedesc" "$fileWithDirTemp"
          fi
        fi 
      fi
    fi
  done

  return 0
}

# Faz download do pacote e desempacota
downloadPackage() {
  memPorcent="$1" # Porcentagem de espaço disponivel
  rank="$2"
  packageName="$3"
  inst="$4"
  vote="$5"
  old="$6"
  recent="$7"
  no_files="$8"
  maintainer="$9"
  maintainerFormat="${maintainer//\'/\'\'}"
  
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
    #url="http://ubuntu.c3sl.ufpr.br/ubuntu/$fn"
    url="http://ftp.br.debian.org/debian/$fn"
    
    # Verifica se o pacote já existe na pasta DIR_PACKAGES
    if [ -f "$DIR_FULL/$DIR_PACKAGES/$(basename "$fn")" ]; then
      echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Pacote $packageName encontrado na pasta $DIR_PACKAGES."
      success=true
      break
    fi

    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Tentando baixar pacote... ($url)"
    # Faz download do pacote para a pasta DIR_TEMP se ele ainda não existe
    if wget -P "$DIR_PACKAGES/" "$url"; then
      echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Download do pacote $packageName completado com sucesso."
      success=true
      break
    fi
  done


  # Verifica se o download foi bem-sucedido
  if [ "$success" = false ]; then  
    logError "Não foi possível baixar o pacote $packageName"

    datetime=$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')

    # Comando SQL para inserir um pacote .deb
    insert_pacote="INSERT INTO deb_package (name ,download_date, download_url, birthYear, rank, installed_users, regular_users, infrequent_users, recent_upgrafes, missing_info_users, maintainer) VALUES ('$packageName', '$datetime', null, null, $rank, $inst, $vote, $old, $recent, $no_files, '$maintainerFormat');"

    # Executar comando SQL usando sqlite3 e pegar o ID do pacote inserido
    sqlite3 $DATABASE "$insert_pacote"

    return 1
  fi

  # Abre arquivo .deb no diretório dir
  deb=$(basename "$url")  

  # Desempacota o arquivo .deb da pasta DIR_PACKAGES para pasta DIR_TEMP"
  if ! output=$(dpkg-deb -X "$DIR_PACKAGES/$deb" "$DIR_TEMP"); then
    logError "Erro ao desempacotar $deb"
    return 1
  fi

  echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Pacote $deb desempacotado com sucesso."


  if [ $memPorcent -gt 93 ]; then
    rm $DIR_PACKAGES/$deb
  fi

  # Define o ano atual
  CURRENT_YEAR=$(date +"%Y")

  birthYear=0
  # Verifica se o arquivo de copyright existe
  COPYRIGHT_FILE="$DIR_TEMP/usr/share/doc/$packageName/copyright"
  if [ -f "$COPYRIGHT_FILE" ]; then
    # Extrai todos os anos mencionados no arquivo de copyright, filtra por um intervalo razoável
    # e pega o primeiro ano (o mais antigo)
    birthYear=$(grep -o '[1-2][0-9]\{3\}' "$COPYRIGHT_FILE" | sort | uniq | awk -v min=1960 -v max=$CURRENT_YEAR '$0 >= min && $0 <= max' | head -n 1)
    if [ -n "$birthYear" ]; then
      echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Ano: $birthYear"
    else
      birthYear=0
    fi  
  else
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Arquivo de copyright não encontrado."
  fi

  datetime=$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')

  # Comando SQL para inserir um pacote .deb
  insert_pacote="INSERT INTO deb_package (name ,download_date, download_url, birthYear, rank, installed_users, regular_users, infrequent_users, recent_upgrafes, missing_info_users, maintainer) VALUES ('$packageName', '$datetime', '$url', $birthYear, $rank, $inst, $vote, $old, $recent, $no_files, '$maintainerFormat');"

  # Executar comando SQL usando sqlite3 e pegar o ID do pacote inserido
  package_id=$(sqlite3 $DATABASE "$insert_pacote; SELECT last_insert_rowid();")

  if [ $? -eq 0 ]; then
    processFiles "$output" "$package_id" "$packageName"
  else
    logError "Erro ao obter package_id - $packageName $deb"
  fi  

  rm -rf "$DIR_TEMP" # Remove a pasta DIR_TEMP

  return 0
}

start() {
  # O primeiro argumento é o número da linha de início
  local inicio=${1:-1}  # Usa 1 como padrão se nenhum número for fornecido
  
  local total_linhas=$(wc -l < "$LIST_DEBIAN_PACKAGES")
  local fim=${2:-$total_linhas}  # Usa o total de linhas como padrão se nenhum número for fornecido
  
  touch $LOGFILE # Cria o arquivo para logs de erros
  mkdir $DIR_PACKAGES # Cria pasta para salvar os pacotes
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
  
    # Obtém a porcentagem do espaço do HD
    memPorcent=$(df -h / | grep ^/ | awk '{print $5}' | tr -d '%')
  
    rank=$(echo "$linha" | awk '{print $1}')
    name=$(echo "$linha" | awk '{print $2}')
    inst=$(echo "$linha" | awk '{print $3}')
    vote=$(echo "$linha" | awk '{print $4}')
    old=$(echo "$linha" | awk '{print $5}')
    recent=$(echo "$linha" | awk '{print $6}')
    no_files=$(echo "$linha" | awk '{print $7}')
    maintainer=$(echo "$linha" | awk '{print substr($0, index($0,$8))}')

    # Faz o Download e Desempacota o pacote
    echo ""
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S' -d '-3 hour')] Pacote $((contador + 1)) - $linha (Mem $memPorcent%)"
    downloadPackage "$memPorcent" "$rank" "$name" "$inst" "$vote" "$old" "$recent" "$no_files" "$maintainer"

    # Limpa o terminal
    #clear
    
    # Incrementa o contador
    ((contador++))
    
    # Sai do loop após ler X linhas
    # if [ $contador -eq 2000 ]; then
    #   break
    # fi
  done
}

# Chama a função start com o número da linha como argumento
start "$1" "$2"
