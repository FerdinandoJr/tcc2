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

# TOTAL DE PACOTES COM IPCS ENCONTRADOS
SELECT COUNT(DISTINCT package_id) AS num_packages_with_ipc
FROM executable_files
WHERE pipe = TRUE
   OR fifo = TRUE
   OR socket = TRUE
   OR pseudo_terminal = TRUE
   OR sysv_message_queues = TRUE
   OR posix_message_queues = TRUE
   OR cross_memory_attach = TRUE
   OR sysv_shared_memory = TRUE
   OR posix_shared_memory = TRUE
   OR mmap = TRUE
   OR sysv_semaphores = TRUE
   OR posix_semaphores = TRUE
   OR eventfd = TRUE
   OR file_and_record_locks = TRUE
   OR mutexes = TRUE
   OR condition_variables = TRUE
   OR barriers = TRUE
   OR read_write_locks = TRUE;


# RANKING DE PACOTES QUE TEVE MAIS ARQUIVOS COM IPCS ENCONTRADOS 
SELECT dp.id , dp.name, COUNT(ef.id) AS ipc_file_count
FROM deb_package dp
JOIN executable_files ef ON dp.id = ef.package_id
WHERE ef.pipe = TRUE
   OR ef.fifo = TRUE
   OR ef.socket = TRUE
   OR ef.pseudo_terminal = TRUE
   OR ef.sysv_message_queues = TRUE
   OR ef.posix_message_queues = TRUE
   OR ef.cross_memory_attach = TRUE
   OR ef.sysv_shared_memory = TRUE
   OR ef.posix_shared_memory = TRUE
   OR ef.mmap = TRUE
   OR ef.sysv_semaphores = TRUE
   OR ef.posix_semaphores = TRUE
   OR ef.eventfd = TRUE
   OR ef.file_and_record_locks = TRUE
   OR ef.mutexes = TRUE
   OR ef.condition_variables = TRUE
   OR ef.barriers = TRUE
   OR ef.read_write_locks = TRUE
GROUP BY dp.id, dp.name
ORDER BY ipc_file_count DESC;

# PACOTES QUE TEVE MAIS IPCS ENCONTRADOS
SELECT dp.id, dp.name, SUM(
    (ef.pipe + ef.fifo + ef.socket + ef.pseudo_terminal + ef.sysv_message_queues + 
    ef.posix_message_queues + ef.cross_memory_attach + ef.sysv_shared_memory + 
    ef.posix_shared_memory + ef.mmap + ef.sysv_semaphores + ef.posix_semaphores + 
    ef.eventfd + ef.file_and_record_locks + ef.mutexes + ef.condition_variables + 
    ef.barriers + ef.read_write_locks)
) AS total_ipc_features
FROM deb_package dp
JOIN executable_files ef ON dp.id = ef.package_id
GROUP BY dp.id, dp.name
ORDER BY total_ipc_features DESC;
