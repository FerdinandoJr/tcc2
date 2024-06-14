import sqlite3
import os

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

packages = {}
# ----------- INICIANDO PROCESSO -----------


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
    # Excluir o arquivo do banco de dados existente, se houver
    if os.path.exists(db_filename):
        os.remove(db_filename)

    conn = sqlite3.connect(db_filename)
    cursor = conn.cursor()
    
    # Criar a tabela
    cursor.execute("""
		CREATE TABLE package_ipc_data (
			id INTERGER PRIMARY KEY,
			name TEXT,
			inst INTEGER,
			pipe BOOLEAN,
			fifo BOOLEAN,
			socket BOOLEAN,
			pseudo_terminal BOOLEAN,
			sysv_message_queues BOOLEAN,
			posix_message_queues BOOLEAN,
			cross_memory_attach BOOLEAN,
			sysv_shared_memory BOOLEAN,
			posix_shared_memory BOOLEAN,
			mmap BOOLEAN,
			sysv_semaphores BOOLEAN,
			posix_semaphores BOOLEAN,
			eventfd BOOLEAN,
			file_and_record_locks BOOLEAN,
			mutexes BOOLEAN,
			condition_variables BOOLEAN,
			barriers BOOLEAN,
			read_write_locks BOOLEAN,
			w_p REAL,
			ipcs_p TEXT
		);
    """)
    
    # Inserir dados
    for name, data in package_data.items():
        ipc_values = tuple(data["ipc_flags"])
        cursor.execute("""
        INSERT INTO package_ipc_data (
            id, name, inst, pipe, fifo, socket, pseudo_terminal, sysv_message_queues,
            posix_message_queues, cross_memory_attach, sysv_shared_memory,
            posix_shared_memory, mmap, sysv_semaphores, posix_semaphores,
            eventfd, file_and_record_locks, mutexes, condition_variables,
            barriers, read_write_locks, w_p, ipcs_p
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (data["id"], name, data["inst"], *ipc_values, data["w"], ', '.join(data["ipcs"])))
    
    conn.commit()
    conn.close()


# Criar a tabela e inserir os dados
createData()
createDatabase(packages)

# Fechar a conexão
conn.close()
