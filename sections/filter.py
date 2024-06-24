import os

# Diretório onde os arquivos de saída estão localizados
output_dir = 'output'

# Nome do arquivo de resposta
response_filename = 'ipc_summary.txt'

# Função para processar cada arquivo de saída
def process_ipc_stats_file(filename):
    section_name = filename.split('_ipc_stats.txt')[0]
    ipc_stats = []
    
    with open(os.path.join(output_dir, filename), 'r') as file:
        # next(file)  # pular o cabeçalho
        for line in file:
            ipc_type, count, percentage = line.strip().split()
            ipc_stats.append((ipc_type, float(percentage)))
    
    # Ordenar IPCs por porcentagem em ordem decrescente
    ipc_stats.sort(key=lambda x: x[1], reverse=True)
    
    # Formatar o resultado
    formatted_stats = ' '.join([f'{ipc[0]}({ipc[1]:.2f})' for ipc in ipc_stats])
    return f'{section_name} {formatted_stats}'

# Lista de arquivos de saída
ipc_files = [f for f in os.listdir(output_dir) if f.endswith('_ipc_stats.txt')]

# Processar todos os arquivos e escrever o arquivo de resposta
with open(response_filename, 'w') as response_file:
    for ipc_file in ipc_files:
        response_file.write(process_ipc_stats_file(ipc_file) + '\n')

print(f"Arquivo de resumo criado: {response_filename}")
