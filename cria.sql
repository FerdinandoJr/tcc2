CREATE TABLE deb_package (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  download_date DATETIME,
  download_url TEXT,
  birthYear INTEGER,
  rank INTEGER,
  installed_users INTEGER,
  regular_users INTEGER,
  infrequent_users INTEGER,
  recent_upgrafes INTEGER,
  missing_info_users INTEGER,
  maintainer TEXT
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

INSERT INTO file_type (type_name) VALUES ('ELF executable');
INSERT INTO file_type (type_name) VALUES ('ELF shared-library');
INSERT INTO file_type (type_name) VALUES ('ELF statically');
INSERT INTO file_type (type_name) VALUES ('POSIX Shell Script');
INSERT INTO file_type (type_name) VALUES ('Python Script');
INSERT INTO file_type (type_name) VALUES ('Perl Script');
INSERT INTO file_type (type_name) VALUES ('Bourne-Again Shell Script');
INSERT INTO file_type (type_name) VALUES ('AWK Script');