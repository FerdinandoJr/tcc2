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
