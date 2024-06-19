import subprocess
import sqlite3
import os
from collections import Counter


# Conectar ao banco de dados SQLite
conn = sqlite3.connect('base.db3')
cursor = conn.cursor()


# ----------- COLETANDO INFORMAÇÕES -----------

# Executar a consulta SQL para obter o valor máximo de installed_users
cursor.execute("SELECT MAX(installed_users) FROM deb_package")
inst_max = cursor.fetchone()[0]

# Lista de IPCs
ipc_list = [
    'pipe', 'fifo', 'socket', 'pseudo_terminal', 'sysv_message_queues',
    'posix_message_queues', 'cross_memory_attach', 'sysv_shared_memory',
    'posix_shared_memory', 'mmap', 'sysv_semaphores', 'posix_semaphores',
    'eventfd', 'file_and_record_locks', 'mutexes', 'condition_variables',
    'barriers', 'read_write_locks'
]

# Criar o mapa "R" com os IPCs como chaves e valores iniciais 0
# R = {ipc: 0 for ipc in ipc_list}

# Contador para armazenar as ocorrências das seções
section_counter = Counter()


# Dicionário de seções e seus respectivos IDs


packages = {}
# ----------- INICIANDO PROCESSO -----------

def get_package_section(package_name):
    try:
        # Executa o comando apt-cache show <nome_do_pacote>
        result = subprocess.run(['apt-cache', 'show', package_name], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        # Verifica se o comando foi executado com sucesso
        if result.returncode != 0:
            raise Exception(f"Erro ao executar o comando: {result.stderr}")
        
        # Procura pela linha que começa com "Section:"
        for line in result.stdout.split('\n'):
            if line.startswith("Section:"):
                return line.split(":")[1].strip()
        
        # Se a seção não for encontrada
        raise Exception("Seção não encontrada no resultado do comando.")
    
    except Exception as e:
        return str(e)

def get_package_section_id(package_name):
    try:
        # Obtém a seção do pacote
        section_name = get_package_section(package_name)
        
        # Retorna o section_id baseado no section_name do dicionário
        section_id = sections.get(section_name)
        
        if section_id:
            return section_id
        else:
            return f"Section '{section_name}' não encontrada no dicionário de seções."
    
    except Exception as e:
        return str(e)


def w(inst_p):
    return inst_p / inst_max

def createData():
	query = """
	SELECT dp.id, dp.name, dp.installed_users,
		MAX(ef.pipe) AS pipe,
		MAX(ef.fifo) AS fifo,
		MAX(ef.socket) AS socket,
		MAX(ef.pseudo_terminal) AS pseudo_terminal,
		MAX(ef.sysv_message_queues) AS sysv_message_queues,
		MAX(ef.posix_message_queues) AS posix_message_queues,
		MAX(ef.cross_memory_attach) AS cross_memory_attach,
		MAX(ef.sysv_shared_memory) AS sysv_shared_memory,
		MAX(ef.posix_shared_memory) AS posix_shared_memory,
		MAX(ef.mmap) AS mmap,
		MAX(ef.sysv_semaphores) AS sysv_semaphores,
		MAX(ef.posix_semaphores) AS posix_semaphores,
		MAX(ef.eventfd) AS eventfd,
		MAX(ef.file_and_record_locks) AS file_and_record_locks,
		MAX(ef.mutexes) AS mutexes,
		MAX(ef.condition_variables) AS condition_variables,
		MAX(ef.barriers) AS barriers,
		MAX(ef.read_write_locks) AS read_write_locks
	FROM deb_package dp
	JOIN executable_files ef ON ef.package_id = dp.id
	WHERE ef.file_type_id in (1, 2)
	GROUP BY dp.id, dp.name;

	"""

	# Executar a consulta SQL
	cursor.execute(query)

	# Recuperar os resultados da consulta
	results = cursor.fetchall()

	for row in results:
		id = int(row[0])
		name = row[1]
		inst_p = int(row[2])
		ipcs = [ipc_list[i] for i, val in enumerate(row[3:]) if val == 1]
		ipc_flags = [1 if val == 1 else 0 for val in row[3:]]
		
		packages[name] = {
			"id": id,
			"inst": inst_p,
			"w": w(inst_p),
			"ipcs": ipcs,
			"ipc_flags": ipc_flags
		}


def createDatabase(package_data, db_filename='base_ipcs.db3'):
    # Inserir dados
    with open('package_data_output.txt', 'w') as file:
        cont = 1
        for name, data in package_data.items():
            # ipc_values = tuple(data["ipc_flags"])
            section = get_package_section(name)
            section_counter[section] += 1
            file.write(f"{cont} {name} {section}\n")
            print(f"{cont} {name} {section}")
            cont += 1
    with open('package_data_output_sections.txt', 'w') as file:
        for section, count in section_counter.items():
            file.write(f"{section} {count}\n")
# Criar a tabela e inserir os dados
createData()
createDatabase(packages)

# Fechar a conexão
conn.close()
