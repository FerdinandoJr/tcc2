import sqlite3
import os

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
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Função para executar a consulta e salvar os resultados em um arquivo TXT
def save_ipc_stats_for_section(section_name, section_id):
    query = f"""
    SELECT
        ipc_type,
        COUNT(*) AS count
    FROM (
        SELECT
            CASE
                WHEN pipe THEN 'pipe'
                WHEN fifo THEN 'fifo'
                WHEN socket THEN 'socket'
                WHEN pseudo_terminal THEN 'pseudo_terminal'
                WHEN sysv_message_queues THEN 'sysv_message_queues'
                WHEN posix_message_queues THEN 'posix_message_queues'
                WHEN cross_memory_attach THEN 'cross_memory_attach'
                WHEN sysv_shared_memory THEN 'sysv_shared_memory'
                WHEN posix_shared_memory THEN 'posix_shared_memory'
                WHEN mmap THEN 'mmap'
                WHEN sysv_semaphores THEN 'sysv_semaphores'
                WHEN posix_semaphores THEN 'posix_semaphores'
                WHEN eventfd THEN 'eventfd'
                WHEN file_and_record_locks THEN 'file_and_record_locks'
                WHEN mutexes THEN 'mutexes'
                WHEN condition_variables THEN 'condition_variables'
                WHEN barriers THEN 'barriers'
                WHEN read_write_locks THEN 'read_write_locks'
            END AS ipc_type
        FROM
            package_ipc_data
        WHERE
            section_id = {section_id}
    ) AS ipc_counts
    WHERE ipc_type is not null
    GROUP BY
        ipc_type
    ORDER BY
        count DESC;
    """

    cursor = conn.cursor()
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()

    # Calcular a soma total das contagens
    total_count = sum(row[1] for row in results)

    # Salvar os resultados em um arquivo TXT
    filename = os.path.join(output_dir, f'{section_name}_ipc_stats.txt')
    with open(filename, 'w') as txtfile:
        # txtfile.write('ipc_type count percentage\n')
        for row in results:
            percentage = (row[1] * 100.0) / total_count
            txtfile.write(f'{row[0]} {row[1]} {percentage:.2f}\n')

# Executar a função para todas as seções
for section_name, section_id in sections.items():
    save_ipc_stats_for_section(section_name, section_id)

# Fechar a conexão com o banco de dados
conn.close()
