CREATE TABLE deb_package (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  download_date DATETIME,
  download_url TEXT,
  birthYear INTEGER
);

CREATE TABLE file_type (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_name TEXT NOT NULL UNIQUE
);

CREATE TABLE executable_files (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  package_id INTEGER,
  file_type_id INTEGER,
  name TEXT NOT NULL,
  pipe BOOLEAN DEFAULT FALSE,
  fifo BOOLEAN DEFAULT FALSE,
  socket BOOLEAN DEFAULT FALSE,
  pseudo_terminal BOOLEAN DEFAULT FALSE,
  sysv_message_queues BOOLEAN DEFAULT FALSE,
  posix_message_queues BOOLEAN DEFAULT FALSE,
  cross_memory_attach BOOLEAN DEFAULT FALSE,
  sysv_shared_memory BOOLEAN DEFAULT FALSE,
  posix_shared_memory BOOLEAN DEFAULT FALSE,
  mmap BOOLEAN DEFAULT FALSE,
  anonymous_memory_mapping BOOLEAN DEFAULT FALSE,
  sysv_semaphores BOOLEAN DEFAULT FALSE,
  posix_semaphores BOOLEAN DEFAULT FALSE,
  eventfd BOOLEAN DEFAULT FALSE,
  file_and_record_locks BOOLEAN DEFAULT FALSE,
  mutexes BOOLEAN DEFAULT FALSE,
  condition_variables BOOLEAN DEFAULT FALSE,
  barriers BOOLEAN DEFAULT FALSE,
  read_write_locks BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (package_id) REFERENCES deb_package (id),
  FOREIGN KEY (file_type_id) REFERENCES file_type (id)
);

INSERT INTO file_type (type_name) VALUES ('ELF');
INSERT INTO file_type (type_name) VALUES ('Symbolic link');
INSERT INTO file_type (type_name) VALUES ('AWK Script');
INSERT INTO file_type (type_name) VALUES ('Perl Script');
INSERT INTO file_type (type_name) VALUES ('Bourne-Again Shell Script');
INSERT INTO file_type (type_name) VALUES ('POSIX Shell Script');
INSERT INTO file_type (type_name) VALUES ('Python Script');
INSERT INTO file_type (type_name) VALUES ('Others');


SELECT 
    ft.type_name ,
    COUNT(ef.id) AS count,
    (COUNT(ef.id) * 100.0 / (SELECT COUNT(*) FROM executable_files)) AS percentage
FROM 
    executable_files ef
INNER JOIN 
    file_type ft ON ef.file_type_id = ft.id
GROUP BY 
    ft.type_name
ORDER BY 
    percentage DESC;


SELECT  COUNT(*) AS package_total from deb_package dp; 

SELECT COUNT(*) AS files_total from executable_files ef; 

SELECT 
    SUM(CASE WHEN pipe = TRUE THEN 1 ELSE 0 END) AS pipe,
    SUM(CASE WHEN fifo  = TRUE THEN 1 ELSE 0 END) AS fifo,
    SUM(CASE WHEN socket = TRUE THEN 1 ELSE 0 END) AS socket,
    SUM(CASE WHEN pseudo_terminal = TRUE THEN 1 ELSE 0 END) AS pseudo_terminal,
    SUM(CASE WHEN sysv_message_queues = TRUE THEN 1 ELSE 0 END) AS sysv_message_queues,
    SUM(CASE WHEN posix_message_queues = TRUE THEN 1 ELSE 0 END) AS posix_message_queues,
    SUM(CASE WHEN cross_memory_attach = TRUE THEN 1 ELSE 0 END) AS cross_memory_attach,
    SUM(CASE WHEN sysv_shared_memory = TRUE THEN 1 ELSE 0 END) AS sysv_shared_memory,
    SUM(CASE WHEN posix_shared_memory = TRUE THEN 1 ELSE 0 END) AS posix_shared_memory,
    SUM(CASE WHEN mmap = TRUE THEN 1 ELSE 0 END) AS mmap,
    SUM(CASE WHEN anonymous_memory_mapping = TRUE THEN 1 ELSE 0 END) AS anonymous_memory_mapping,
    SUM(CASE WHEN sysv_semaphores = TRUE THEN 1 ELSE 0 END) AS sysv_semaphores,
    SUM(CASE WHEN posix_semaphores = TRUE THEN 1 ELSE 0 END) AS posix_semaphores,
    SUM(CASE WHEN eventfd = TRUE THEN 1 ELSE 0 END) AS eventfd,
    SUM(CASE WHEN file_and_record_locks = TRUE THEN 1 ELSE 0 END) AS file_and_record_locks,
    SUM(CASE WHEN mutexes = TRUE THEN 1 ELSE 0 END) AS mutexes,
    SUM(CASE WHEN condition_variables = TRUE THEN 1 ELSE 0 END) AS condition_variables,
    SUM(CASE WHEN barriers = TRUE THEN 1 ELSE 0 END) AS barriers,
    SUM(CASE WHEN read_write_locks = TRUE THEN 1 ELSE 0 END) AS rw_lock
FROM 
    executable_files ef;
