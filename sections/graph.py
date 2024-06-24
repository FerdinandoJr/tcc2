# import os
# import pandas as pd
# import matplotlib.pyplot as plt

# # Diretório onde os arquivos de saída estão localizados
# output_dir = 'output'
# charts_dir = 'charts'

# # Criar o diretório para armazenar os gráficos, se não existir
# if not os.path.exists(charts_dir):
#     os.makedirs(charts_dir)

# # Mapeamento de nomes antigos para novos nomes de IPC
# ipc_name_mapping = {
#     'None': 'Nenhum',
#     'pipe': 'pipe',
#     'fifo': 'FIFO',
#     'socket': 'socket',
#     'pseudo_terminal': 'pseudoterminal',
#     'sysv_message_queues': 'SysV MQ',
#     'posix_message_queues': 'POSIX MQ',
#     'cross_memory_attach': 'CMA',
#     'sysv_shared_memory': 'SysV SHM',
#     'posix_shared_memory': 'POSIX SHM',
#     'mmap': 'mmap',
#     'sysv_semaphores': 'SysV sem',
#     'posix_semaphores': 'POSIX sem',
#     'eventfd': 'eventfd',
#     'file_and_record_locks': 'trava arq',
#     'mutexes': 'mutex',
#     'condition_variables': 'var. cond',
#     'barriers': 'barreira',
#     'read_write_locks': 'rwlock'
# }

# # Função para processar cada arquivo de saída e gerar gráficos de barra
# def generate_bar_chart(filename):
#     section_name = filename.split('_ipc_stats.txt')[0]
    
#     # Ler os dados do arquivo
#     data = []
#     with open(os.path.join(output_dir, filename), 'r') as file:
#         for line in file:
#             ipc_type, count, percentage = line.strip().split()
#             new_ipc_type = ipc_name_mapping.get(ipc_type, ipc_type)  # Mapear o nome do IPC
#             data.append((new_ipc_type, int(count), float(percentage)))
    
#     # Criar um DataFrame
#     df = pd.DataFrame(data, columns=['IPC', 'Count', 'Porcentagem'])
    
#     # Gerar gráfico de barras com porcentagem no eixo Y
#     plt.figure(figsize=(12, 6))
#     plt.bar(df['IPC'], df['Porcentagem'], color='skyblue')
#     plt.xlabel('IPC')
#     plt.ylabel('Porcentagem')
#     plt.title(f'Porcentagem de IPC por Seção: {section_name}')
#     plt.ylim(0, 100)  # Definir limite do eixo Y de 0 a 100
#     plt.xticks(rotation=45, ha='right')
#     plt.tight_layout()
    
    
#     # Salvar o gráfico
#     chart_filename = os.path.join(charts_dir, f'{section_name}_ipc_chart.png')
#     plt.savefig(chart_filename)
#     plt.close()

# # Lista de arquivos de saída
# ipc_files = [f for f in os.listdir(output_dir) if f.endswith('_ipc_stats.txt')]

# # Gerar gráficos de barra para todos os arquivos de saída
# for ipc_file in ipc_files:
#     generate_bar_chart(ipc_file)

# print(f"Gráficos de barra criados na pasta: {charts_dir}")
