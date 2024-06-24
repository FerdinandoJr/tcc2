-- SELECT DE PEGAR TOTAL E PORCETAGEM DE PACOTES PELA SECTIONS

SELECT 
    s.section_name,
    COUNT(p.id) AS package_count,
    (COUNT(p.id) * 100.0 / (SELECT COUNT(pid.id) FROM package_ipc_data pid)) AS percentage
FROM 
    package_sections s
LEFT JOIN 
    package_ipc_data p ON s.id = p.section_id
GROUP BY 
    s.id, s.section_name
ORDER BY 
    package_count DESC    

-- SELECT PARA PEGAR QUANTIDADE DE PACOTES QUE TENHA OCORRENCIA DE 1 IPC
SELECT 
    s.section_name,
    COUNT(p.id) AS package_count,
    (COUNT(p.id) * 100.0 / (SELECT COUNT(pid.id) FROM package_ipc_data pid WHERE 
        pid.pipe OR pid.fifo OR pid.socket OR pid.pseudo_terminal OR 
        pid.sysv_message_queues OR pid.posix_message_queues OR 
        pid.cross_memory_attach OR pid.sysv_shared_memory OR 
        pid.posix_shared_memory OR pid.mmap OR pid.sysv_semaphores OR 
        pid.posix_semaphores OR pid.eventfd OR pid.file_and_record_locks OR 
        pid.mutexes OR pid.condition_variables OR pid.barriers OR 
        pid.read_write_locks)) AS percentage
FROM 
    package_sections s
LEFT JOIN 
    package_ipc_data p ON s.id = p.section_id
WHERE 
    p.pipe OR p.fifo OR p.socket OR p.pseudo_terminal OR 
    p.sysv_message_queues OR p.posix_message_queues OR 
    p.cross_memory_attach OR p.sysv_shared_memory OR 
    p.posix_shared_memory OR p.mmap OR p.sysv_semaphores OR 
    p.posix_semaphores OR p.eventfd OR p.file_and_record_locks OR 
    p.mutexes OR p.condition_variables OR p.barriers OR 
    p.read_write_locks
GROUP BY 
    s.id, s.section_name
ORDER BY 
    package_count DESC;


-- SELECT DE PEGAR QUANTIDADE TOTAL DE CADA IPC PELAS SECTIONS
SELECT 
    s.section_name,
    COUNT(CASE WHEN p.pipe THEN 1 ELSE NULL END) AS pipe_count,
    COUNT(CASE WHEN p.fifo THEN 1 ELSE NULL END) AS fifo_count,
    COUNT(CASE WHEN p.socket THEN 1 ELSE NULL END) AS socket_count,
    COUNT(CASE WHEN p.pseudo_terminal THEN 1 ELSE NULL END) AS pseudo_terminal_count,
    COUNT(CASE WHEN p.sysv_message_queues THEN 1 ELSE NULL END) AS sysv_message_queues_count,
    COUNT(CASE WHEN p.posix_message_queues THEN 1 ELSE NULL END) AS posix_message_queues_count,
    COUNT(CASE WHEN p.cross_memory_attach THEN 1 ELSE NULL END) AS cross_memory_attach_count,
    COUNT(CASE WHEN p.sysv_shared_memory THEN 1 ELSE NULL END) AS sysv_shared_memory_count,
    COUNT(CASE WHEN p.posix_shared_memory THEN 1 ELSE NULL END) AS posix_shared_memory_count,
    COUNT(CASE WHEN p.mmap THEN 1 ELSE NULL END) AS mmap_count,
    COUNT(CASE WHEN p.sysv_semaphores THEN 1 ELSE NULL END) AS sysv_semaphores_count,
    COUNT(CASE WHEN p.posix_semaphores THEN 1 ELSE NULL END) AS posix_semaphores_count,
    COUNT(CASE WHEN p.eventfd THEN 1 ELSE NULL END) AS eventfd_count,
    COUNT(CASE WHEN p.file_and_record_locks THEN 1 ELSE NULL END) AS file_and_record_locks_count,
    COUNT(CASE WHEN p.mutexes THEN 1 ELSE NULL END) AS mutexes_count,
    COUNT(CASE WHEN p.condition_variables THEN 1 ELSE NULL END) AS condition_variables_count,
    COUNT(CASE WHEN p.barriers THEN 1 ELSE NULL END) AS barriers_count,
    COUNT(CASE WHEN p.read_write_locks THEN 1 ELSE NULL END) AS read_write_locks_count
FROM 
    package_sections s
LEFT JOIN 
    package_ipc_data p ON s.id = p.section_id
GROUP BY 
    s.id, s.section_name
ORDER BY 
    s.section_name;