#!/bin/bash

# O nome do pacote é o primeiro argumento do script
packageName="$1"

# Verifica se o nome do pacote foi fornecido
if [ -z "$packageName" ]; then
    echo "Erro: Nome do pacote não fornecido."
    exit 1
fi

url=$(apt-cache show $packageName | awk '/^Filename:/ {print "http://ubuntu.c3sl.ufpr.br/ubuntu/"$2; exit}')

echo $url