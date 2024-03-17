CREATE TABLE deb_package (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  download_date DATETIME,
  download_url TEXT
);

CREATE TABLE executable_files (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  package_id INTEGER,
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
  FOREIGN KEY (package_id) REFERENCES deb_package (id)
);
