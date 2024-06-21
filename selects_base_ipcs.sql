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

-- SELECT PARA PEGAR TOTAL GERAL DE IPCS PELAS SECTIONS
SELECT 
    s.section_name,
    SUM(CASE WHEN p.pipe THEN 1 ELSE 0 END +
     CASE WHEN p.fifo THEN 1 ELSE 0 END +
     CASE WHEN p.socket THEN 1 ELSE 0 END +
     CASE WHEN p.pseudo_terminal THEN 1 ELSE 0 END +
     CASE WHEN p.sysv_message_queues THEN 1 ELSE 0 END +
     CASE WHEN p.posix_message_queues THEN 1 ELSE 0 END +
     CASE WHEN p.cross_memory_attach THEN 1 ELSE 0 END +
     CASE WHEN p.sysv_shared_memory THEN 1 ELSE 0 END +
     CASE WHEN p.posix_shared_memory THEN 1 ELSE 0 END +
     CASE WHEN p.mmap THEN 1 ELSE 0 END +
     CASE WHEN p.sysv_semaphores THEN 1 ELSE 0 END +
     CASE WHEN p.posix_semaphores THEN 1 ELSE 0 END +
     CASE WHEN p.eventfd THEN 1 ELSE 0 END +
     CASE WHEN p.file_and_record_locks THEN 1 ELSE 0 END +
     CASE WHEN p.mutexes THEN 1 ELSE 0 END +
     CASE WHEN p.condition_variables THEN 1 ELSE 0 END +
     CASE WHEN p.barriers THEN 1 ELSE 0 END +
     CASE WHEN p.read_write_locks THEN 1 ELSE 0 END) AS ipc_count
FROM 
    package_sections s
JOIN 
    package_ipc_data p ON s.id = p.section_id
GROUP BY 
	s.section_name
ORDER BY 
    ipc_count DESC;


-- SELECT DE PEGAR TOTAL DE CADA IPC PELAS SECTIONS
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