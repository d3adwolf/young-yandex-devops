## Young Yandex DevOps 2023
Итоговый проект Young Yandex по направлению DevOps 2023 года. 

### Предисловие
Из-за работы и учебы пришлось уделить проекту только 4 дня, но, зато все 4 дня сидел non-stop за работой. Хочется уже спать, кушать, отдыхать, как и всем в общем.

Время 00:02, убрал руки от контейнеров в 23:55, пойду загружу актуальные конфиги.

### Этап 0
**Изначальная инфраструктура:**<br>
Домашний сервер Dell R510 с [Proxmox VE 8.0.4](https://proxmox.foreverfunface.ru)
```
Linux proxmox 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 GNU/Linux
```
Внутри LXC контейнер **yy-test** с ubuntu-23.04-standart_23.04-1_amd64
```
Linux yy-test 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 x86_64 x86_64 GNU/Linux
```
Доступ в ресурсы сервера через обратный прокси [Nginx Proxy Manager](https://proxy.foreverfunface.ru).

### Этап 1
**Изучение и настройка бинарника:**
Скачиваем приложение (бинарник), основанный на [Cobra](https://github.com/spf13/cobra)
```
wget https://storage.yandexcloud.net/final-homework/bingo
```
Сделаем бинарник исполняемым в любой точке системы, будто мы его поставили через `apt`, создадим пользователя, чтобы соответствовать правильному подходу по ИБ, да и из под root-а он не запустится.
```
mv bingo /bin/
chmod 755 /bin/bingo
adduser user
usermod -aG sudo user
```
Для запуска сервера нужен конфиг и БД с данными.

Смотрим расположение конфига
```
strace bingo print_current_config
openat(AT_FDCWD, "/opt/bingo/config.yaml", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```
```
mkdir /opt/bingo/
vi /opt/bingo/config.yaml
```
Указываем свою почту: `f3.d3ad.wolf@yandex.ru`, а актуальный конфиг я загрузил в [публичный репозиторий](https://github.com/d3adwolf/young-yandex-public).

Для удобства запустим БД сразу в Docker, установим его по инструкции:<br>
[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) и [Linux post-installation steps for Docker Engine](https://docs.docker.com/engine/install/linux-postinstall/).

Теперь ставим PostreSQL:
Для этого я нашел в интернете готовый docker-compose.yaml, на данный момент изменять его не нужно.
Запускаем через `docker compose up -d`, добавляем тестовые данные в БД `bingo prepare_db`.

### Этап 2
**Запуск бинарника:**

Пробуем запустить сервер
```
bingo run_server
```

Видим ошибку с логами, делаем strace
```
strace bingo run_server
```
Находим несуществующий путь и создаем папку
```
mkdir -p /opt/bongo/logs/6561f4ba98/
touch /opt/bongo/logs/6561f4ba98/main.log
chmod 777 /opt/bongo/logs/6561f4ba98/main.log
```
Пробуем
```
bingo run_server
```
Узнаем какой порт прослушивает Bingo после успешного его запуска
```
ss -ltnp
LISTEN    0    128    *:19225    *:*    users:(("bingo",pid=6849,fd=9))
```

### Этап 3
**Упаковка сервера в контейнер:**

### Разное
**Нахождение мною всех кодов:**
При любом успешном запуске сервера:
```
bingo run_server
```
```
My congratulations.
You were able to start the server.
Here's a secret code that confirms that you did it.
--------------------------------------------------
code:         yoohoo_server_launched
--------------------------------------------------
```
<br><br>
При запросе корневой страницы сайта (`/`):
```
curl http://ip:19225
```
```
Hi. Accept my congratulations. You were able to launch this app.
In the text of the task, you were given a list of urls and requirements for their work.
Get on with it. You can do it, you'll do it.
--------------------------------------------------
code:         index_page_is_awesome
--------------------------------------------------
```
<br><br>
Да, я пытался найти в исходниках пасхалку, советы, но нашел код, который можно получить, заблочив Google домен:
```
xxd bingo
```
```
0085baf0: 6978 2069 742e 0a48 6572 6527 7320 6120  ix it..Here's a 
0085bb00: 7365 6372 6574 2063 6f64 6520 7468 6174  secret code that
0085bb10: 2063 6f6e 6669 726d 7320 7468 6174 2079   confirms that y
0085bb20: 6f75 2064 6964 2069 742e 0a2d 2d2d 2d2d  ou did it..-----
0085bb30: 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  ----------------
0085bb40: 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  ----------------
0085bb50: 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d0a 636f  -------------.co
0085bb60: 6465 3a20 2020 2020 2020 2020 676f 6f67  de:         goog
0085bb70: 6c65 5f64 6e73 5f69 735f 6e6f 745f 6874  le_dns_is_not_ht
0085bb80: 7470 0a2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  tp.-------------
0085bb90: 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  ----------------
0085bba0: 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  ----------------
0085bbb0: 2d2d 2d2d 2d0a 2020 2020 3c68 746d 6c3e  -----.    <html>
```
Либо идём по правильному пути:
```
netstat -anp | grep bingo
tcp        0      1 172.25.251.86:42506     8.8.8.8:80              SYN_SENT    74648/bingo
```
Эту команду выполняем вне контейнера, а в compose указываем сеть `host`, чтобы `iptables` хоста работал на сам контейнер:
```
iptables -t filter -A OUTPUT -d 8.8.8.8/32 -j REJECT
```
```
Congratulations.
You were able to figure out why
the application is slow to start and fix it.
Here's a secret code that confirms that you did it.
--------------------------------------------------
code:         google_dns_is_not_http
--------------------------------------------------
```
<br><br>


CREATE INDEX customers_id_indx ON public.customers (id);
CREATE INDEX movies_id_indx ON public.movies (id DESC);
CREATE INDEX movies_name_indx ON public.movies ("name");
CREATE INDEX movies_year_indx ON public.movies ("year" DESC);
CREATE INDEX sessions_id_indx ON public.sessions (id DESC);

SELECT indexname, tablename
FROM pg_indexes;

```
# DB Version: 16
# OS Type: linux
# DB Type: web
# Total Memory (RAM): 8 GB
# CPUs num: 16
# Data Storage: ssd

max_connections = 200
shared_buffers = 2GB
effective_cache_size = 6GB
maintenance_work_mem = 512MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 2621kB
huge_pages = off
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 16
max_parallel_workers_per_gather = 4
max_parallel_workers = 16
max_parallel_maintenance_workers = 4
```

https://pgtune.leopard.in.ua/
