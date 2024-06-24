import sqlite3
import os
import shutil

# Mapeamento de seções e seus IDs
sections = {
    'admin': 1,
    'libs': 2,
    'utils': 3,
    'perl': 4,
    'shells': 5,
    'net': 6,
    'interpreters': 7,
    'text': 8,
    'web': 9,
    'editors': 10,
    'x11': 11,
    'doc': 12,
    'misc': 13,
    'python': 14,
    'fonts': 15,
    'vcs': 16,
    'math': 17,
    'libdevel': 18,
    'devel': 19,
    'oldlibs': 20,
    'otherosfs': 21,
    'video': 22,
    'comm': 23,
    'graphics': 24,
    'sound': 25,
    'httpd': 26,
    'gnome': 27,
    'science': 28,
    'java': 29,
    'mail': 30,
    'games': 31,
    'lisp': 32,
    'kde': 33,
    'xfce': 34,
    'gnustep': 35,
    'database': 36,
    'kernel': 37,
    'ruby': 38,
    'zope': 39,
    'tex': 40,
    'php': 41,
    'cli-mono': 42,
    'gnu-r': 43,
    'electronics': 44,
    'golang': 45,
    'haskell': 46,
    'rust': 47,
    'ocaml': 48,
    'education': 49,
    'hamradio': 50,
    'embedded': 51,
    'news': 52,
    'debug': 53,
    'javascript': 54,
    'metapackages': 55
}


# Conectar ao banco de dados SQLite
conn = sqlite3.connect('base_ipcs.db3')

# Criar pasta de saída se não existir
output_dir = 'output'
shutil.rmtree('output')

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Função para executar a consulta e salvar os resultados em um arquivo TXT
def save_ipc_stats_for_section(section_name, section_id):    
    query = f"""
        SELECT
            CASE
                WHEN pipe THEN 'pipe, '
                ELSE ''
            END ||
            CASE
                WHEN fifo THEN 'fifo, '
                ELSE ''
            END ||
            CASE
                WHEN socket THEN 'socket, '
                ELSE ''
            END ||
            CASE
                WHEN pseudo_terminal THEN 'pseudo_terminal, '
                ELSE ''
            END ||
            CASE
                WHEN sysv_message_queues THEN 'sysv_message_queues, '
                ELSE ''
            END ||
            CASE
                WHEN posix_message_queues THEN 'posix_message_queues, '
                ELSE ''
            END ||
            CASE
                WHEN cross_memory_attach THEN 'cross_memory_attach, '
                ELSE ''
            END ||
            CASE
                WHEN sysv_shared_memory THEN 'sysv_shared_memory, '
                ELSE ''
            END ||
            CASE
                WHEN posix_shared_memory THEN 'posix_shared_memory, '
                ELSE ''
            END ||
            CASE
                WHEN mutexes THEN 'mutexes, '
                ELSE ''
            END ||
            CASE
                WHEN mmap THEN 'mmap, '
                ELSE ''
            END ||
            CASE
                WHEN sysv_semaphores THEN 'sysv_semaphores, '
                ELSE ''
            END ||
            CASE
                WHEN posix_semaphores THEN 'posix_semaphores, '
                ELSE ''
            END ||
            CASE
                WHEN eventfd THEN 'eventfd, '
                ELSE ''
            END ||
            CASE
                WHEN file_and_record_locks THEN 'file_and_record_locks, '
                ELSE ''
            END ||
            CASE
                WHEN condition_variables THEN 'condition_variables, '
                ELSE ''
            END ||
            CASE
                WHEN barriers THEN 'barriers, '
                ELSE ''
            END ||
            CASE
                WHEN read_write_locks THEN 'read_write_locks, '
                ELSE ''
            END AS ipc_types
        FROM
            package_ipc_data
        WHERE
    section_id = {section_id};

    """

    cursor = conn.cursor()
    cursor.execute(query)

    # Processar os resultados e gerar arquivos
    
    ipc_data_count = {
        'pipe': 0,
        'fifo': 0,
        'socket': 0,
        'pseudo_terminal': 0,
        'sysv_message_queues': 0,
        'posix_message_queues': 0,
        'cross_memory_attach': 0,
        'sysv_shared_memory': 0,
        'posix_shared_memory': 0,
        'mutexes': 0,
        'mmap': 0,
        'sysv_semaphores': 0,
        'posix_semaphores': 0,
        'eventfd': 0,
        'file_and_record_locks': 0,
        'condition_variables': 0,
        'barriers': 0,
        'read_write_locks': 0,
        'None': 0
    }

    total_pacotes = 0
    for row in cursor.fetchall():
        ipc_data = row[0] # map
        total_pacotes += 1
        ipc_types = ipc_data.split(', ')
        if ipc_data == "":
            ipc_data_count['None'] += 1
        else :
            for ipc_type in ipc_types:
                if ipc_type in ipc_data_count:
                    ipc_data_count[ipc_type] += 1        
                
    sorted_ipc_data_count = dict(sorted(ipc_data_count.items(), key=lambda x: x[1], reverse=True))
    for ipc_type, count in sorted_ipc_data_count.items():
        # Gerar arquivo para a seção
        if count > 0 :
            output_file = os.path.join(output_dir, f"{section_name}_ipc_stats.txt")
            with open(output_file, 'a') as f:
                percentage = (count / total_pacotes) * 100 if total_pacotes > 0 else 0
                f.write(f"{ipc_type}  {count}  {percentage:.2f}\n") 
            

# save_ipc_stats_for_section('javascript', 54)
# Executar a função para todas as seções
for section_name, section_id in sections.items():
    save_ipc_stats_for_section(section_name, section_id)

# Fechar a conexão com o banco de dados
conn.close()
