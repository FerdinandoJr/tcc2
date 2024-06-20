import subprocess
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


# Dicionário de seções e seus respectivos IDs
sections = {
    'admin' : 1,
	'libs' : 2,
	'utils' : 3,
	'perl' : 4,
	'shells' : 5,
	'net' : 6,
	'interpreters' : 7,
	'text' : 8,
	'web' : 9,
	'editors' : 10,
	'x11' : 11,
	'doc' : 12,
	'misc' : 13,
	'python' : 14,
	'fonts' : 15,
	'vcs' : 16,
	'math' : 17,
	'libdevel' : 18,
	'devel' : 19,
	'oldlibs' : 20,
	'otherosfs' : 21,
	'video' : 22,
	'comm' : 23,
	'graphics' : 24,
	'sound' : 25,
	'httpd' : 26,
	'gnome' : 27,
	'science' : 28,
	'java' : 29,
	'mail' : 30,
	'games' : 31,
	'lisp' : 32,
	'kde' : 33,
	'xfce' : 34,
	'gnustep' : 35,
	'database' : 36,
	'kernel' : 37,
	'ruby' : 38,
	'zope' : 39,
	'tex' : 40,
	'php' : 41,
	'cli-mono' : 42,
	'gnu-r' : 43,
	'electronics' : 44,
	'golang' : 45,
	'haskell' : 46,
	'rust' : 47,
	'ocaml' : 48,
	'education' : 49,
	'hamradio' : 50,
	'embedded' : 51,
	'news' : 52,
	'debug' : 53,
	'javascript' : 54,
	'metapackages' : 55
}

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
                section = line.split(":")[1].strip()
                # Se existir '/', pegamos apenas a parte após '/'
                if '/' in section:
                    section = section.split('/')[1].strip()
                return section
        
        # Se a seção não for encontrada
        raise Exception("Seção não encontrada no resultado do comando.")
    
    except Exception as e:
        return str(e)

def get_or_create_section_id(section_name):
    # Conecta ao banco de dados (substitua 'example.db' pelo nome do seu banco de dados)
    conn = sqlite3.connect('example.db')
    cursor = conn.cursor()

    try:
        # Verifica se a seção existe
        cursor.execute("SELECT id FROM sections WHERE name = ?", (section_name,))
        result = cursor.fetchone()
        
        if result:
            # Se a seção existe, retorna o id
            section_id = result[0]
        else:
            # Se a seção não existe, cria uma nova seção
            cursor.execute("INSERT INTO sections (name) VALUES (?)", (section_name,))
            conn.commit()
            section_id = cursor.lastrowid
        
        return section_id
    finally:
        conn.close()

def get_package_section_id(package_name):
    try:
        # Obtém a seção do pacote
        section_name = get_package_section(package_name)
        
        # Verifica se a seção está no dicionário
        section_id = sections.get(section_name)
        
        if section_id:
            return section_id
        else:
            # Se a seção não está no dicionário, procura ou cria no banco de dados
            return get_or_create_section_id(section_name)
    
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
		CREATE TABLE package_sections (
			id SERIAL PRIMARY KEY,
			section_name VARCHAR(255) UNIQUE NOT NULL
		);
	""")
    print("criou tabela section")
    cursor.execute("""
		INSERT INTO package_sections (id, section_name) VALUES
			( 1, 'admin'),
			( 2, 'libs'),
			( 3, 'utils'),
			( 4, 'perl'),
			( 5, 'shells'),
			( 6, 'net'),
			( 7, 'interpreters'),
			( 8, 'text'),
			( 9, 'web'),
			( 10, 'editors'),
			( 11, 'x11'),
			( 12, 'doc'),
			( 13, 'misc'),
			( 14, 'python'),
			( 15, 'fonts'),
			( 16, 'vcs'),
			( 17, 'math'),
			( 18, 'libdevel'),
			( 19, 'devel'),
			( 20, 'oldlibs'),
			( 21, 'otherosfs'),
			( 22, 'video'),
			( 23, 'comm'),
			( 24, 'graphics'),
			( 25, 'sound'),
			( 26, 'httpd'),
			( 27, 'gnome'),
			( 28, 'science'),
			( 29, 'java'),
			( 30, 'mail'),
			( 31, 'games'),
			( 32, 'lisp'),
			( 33, 'kde'),
			( 34, 'xfce'),
			( 35, 'gnustep'),
			( 36, 'database'),
			( 37, 'kernel'),
			( 38, 'ruby'),
			( 39, 'zope'),
			( 40, 'tex'),
			( 41, 'php'),
			( 42, 'cli-mono'),
			( 43, 'gnu-r'),
			( 44, 'electronics'),
			( 45, 'golang'),
			( 46, 'haskell'),
			( 47, 'rust'),
			( 48, 'ocaml'),
			( 49, 'education'),
			( 50, 'hamradio'),
			( 51, 'embedded'),
			( 52, 'news'),
			( 53, 'debug'),
			( 54, 'javascript'),
			( 55, 'metapackages');
	""")
    print("Populou tabela")
    cursor.execute("""
		CREATE TABLE package_ipc_data (
			id INTEGER PRIMARY KEY,
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
			ipcs_p TEXT,
			section_id INTEGER,
			FOREIGN KEY (section_id) REFERENCES package_sections(id)
		);
    """)
    print("criou tabela packages")
    
    # Inserir dados
    cont = 1
    for name, data in package_data.items():
        ipc_values = tuple(data["ipc_flags"])
        cursor.execute("""
        INSERT INTO package_ipc_data (
            id, name, inst, pipe, fifo, socket, pseudo_terminal, sysv_message_queues,
            posix_message_queues, cross_memory_attach, sysv_shared_memory,
            posix_shared_memory, mmap, sysv_semaphores, posix_semaphores,
            eventfd, file_and_record_locks, mutexes, condition_variables,
            barriers, read_write_locks, w_p, ipcs_p, section_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (data["id"], name, data["inst"], *ipc_values, data["w"], ', '.join(data["ipcs"]), get_package_section_id(name)))
        print(f"{cont} - {name}")        
        cont+=1
    
    conn.commit()
    conn.close()


# Criar a tabela e inserir os dados
createData()
createDatabase(packages)

# Fechar a conexão
conn.close()
