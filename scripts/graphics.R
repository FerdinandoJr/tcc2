# Configurar o knitr
knitr::opts_chunk$set(echo = TRUE)

# Carregar pacotes necessários
require(RSQLite)
require(dplyr)
require(ggplot2)
require(forcats)

# Conectar ao banco de dados
con <- dbConnect(SQLite(), "base.db3")
con2 <- dbConnect(SQLite(), "base_ipcs.db3")

# Carregar tabelas do banco de dados
pkg <- tbl(con, "deb_package")
exec_files <- tbl(con, "executable_files")
pkg_ipc <- tbl(con2, "package_ipc_data")

# Visualizar primeiras linhas das tabelas
pkg %>% head(10)
exec_files %>% head(10)
pkg_ipc %>% head(10)
pkg_ipc %>% filter(name == "dpkg") %>% pull(ipcs_p)

# Ler dados dos arquivos
rank.pop <- read.table("tcc2/rank-pop.dat", header = TRUE)
rank.conta <- read.table("tcc2/rank-conta.dat", header = TRUE)

# Ordenar os dados
rank.pop.ord <- rank.pop %>% arrange(ipc)
rank.conta.ord <- rank.conta %>% arrange(ipc)

# Calcular correlação
cor.sp <- cor(rank.pop.ord$R.ipc, rank.conta.ord$conta, method = "spearman")

# Adicionar nomes gráficos
rank.conta.ord$nomegr <- c("barreira", "var. cond", "CMA", "eventfd", "FIFO", "trava arq", "mmap", "mutex", "pipe", "POSIX mq", "POSIX sem", "POSIX shm", "pseudoterminal", "rwlock", "socket", "SysV mq", "SysV sem", "SysV shm")
rank.pop.ord$nomegr <- c("barreira", "var. cond", "CMA", "eventfd", "FIFO", "trava arq", "mmap", "mutex", "pipe", "POSIX mq", "POSIX sem", "POSIX shm", "pseudoterminal", "rwlock", "socket", "SysV mq", "SysV sem", "SysV shm")

# Arredondar os valores de popularidade para 2 casas decimais
rank.pop.ord <- rank.pop.ord %>%
  mutate(R.ipc = round(R.ipc, 2))

# Plotar gráfico de contagem
rank.conta.ord %>%
  arrange(conta) %>%  # Ordena pela contagem
  mutate(nomegr = factor(nomegr, levels = nomegr)) %>%  # Ajusta os níveis do fator nomegr
  ggplot(aes(x = nomegr, y = conta)) +
  geom_segment(aes(xend = nomegr, yend = 0)) +
  geom_point(size = 4, color = "navy") +
  coord_flip() +
  theme_bw() +
  xlab("") +
  ylab("número de pacotes") +
  geom_text(aes(nomegr, conta + 250, label = conta, fill = NULL), data = rank.conta.ord)

ggsave("pacotes-por-ipc-sem-rotulo.pdf")

# Plotar gráfico de popularidade
rank.pop.ord %>%
  arrange(R.ipc) %>%  # Ordena pela contagem de popularidade
  mutate(nomegr = factor(nomegr, levels = nomegr)) %>%  # Ajusta os níveis do fator nomegr
  ggplot(aes(x = nomegr, y = R.ipc)) +
  geom_segment(aes(xend = nomegr, yend = 0)) +
  geom_point(size = 4, color = "navy") +
  coord_flip() +
  theme_bw() +
  xlab("") +
  ylab("número de pacotes") +
  geom_text(aes(nomegr, R.ipc + 30, label = R.ipc, fill = NULL), data = rank.pop.ord)

ggsave("pacotes-por-ipc-sem-rotulo-pop.pdf")
