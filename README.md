## Young Yandex DevOps 2023
Итоговый проект Young Yandex по направлению DevOps 2023 года. 
<br><br>
### Предисловие
> [!IMPORTANT]\
> Из-за работы и учебы пришлось уделить проекту только 4 дня, но, зато все 4 дня сидел non-stop за работой. Хочется уже спать, кушать, отдыхать, как и всем в общем.
Время 00:02, убрал руки от контейнеров в 23:55, пойду загружу актуальные конфиги.
### Этап 0
**Изначальная инфраструктура:**<br>
Домашний сервер Dell R510 с [Proxmox VE 8.0.4](https://proxmox.foreverfunface.ru)
```bash
Linux proxmox 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 GNU/Linux
```
Внутри LXC контейнер **yy-test** с ubuntu-23.04-standart_23.04-1_amd64
```bash
Linux yy-test 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 x86_64 x86_64 GNU/Linux
```
Доступ к сайтам сервера идет через обратный прокси [Nginx Proxy Manager](https://proxy.foreverfunface.ru)
> [!NOTE]\
> Сайт ещё жив на [youngyandex.ru](https://youngyandex.ru/), текущий [конфиг Bingo](https://youngyandex.ru/config), админка [PostgreSQL](https://pgadmin.youngyandex.ru/)
### Этап 1
**Изучение и настройка бинарника:**<br>
Скачиваем приложение (бинарник), основанный на [Cobra](https://github.com/spf13/cobra)
```bash
wget https://storage.yandexcloud.net/final-homework/bingo
```
Сделаем бинарник исполняемым в любой точке системы, будто мы его поставили через `apt`, создадим пользователя, чтобы соответствовать правильному подходу по ИБ, да и из под root-а он не запустится
```bash
mv bingo /bin/
chmod 755 /bin/bingo
adduser user
usermod -aG sudo user
```
Для запуска сервера нужен конфиг и БД с данными
<br><br>
Смотрим расположение конфига
```bash
strace bingo print_current_config
openat(AT_FDCWD, "/opt/bingo/config.yaml", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```
Для начала узнаем стандартный конфиг
```bash
bingo print_default_config
```
Создадим необходимую папку и конфиг
```bash
mkdir /opt/bingo/
vi /opt/bingo/config.yaml
```
Указываем свою почту: `f3.d3ad.wolf@yandex.ru`, а актуальный конфиг я загрузил в [публичный репозиторий](https://github.com/d3adwolf/young-yandex-public).
- [X] В конфигурации — правильный email<br><br>

**Теперь ставим PostreSQL:**<br>
Для удобства запустим БД сразу в Docker, установим его по инструкции:<br>
[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) и [Linux post-installation steps for Docker Engine](https://docs.docker.com/engine/install/linux-postinstall/)<br><br>
Для этого я нашел в интернете готовый docker-compose.yaml для PostreSQL,<br>на тот момент изменять его не нужно, часть yaml-файла примерно такая
```yaml
postgres:
    container_name: postgres
    image: postgres
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    ports:
      - '5432:5432'
    volumes:
      - postgres:/var/lib/postgresql/data
      - ./custompostgresql.conf:/var/lib/postgresql/data/postgresql.conf
volumes:
  postgres:
    driver: local
```
Изменения в custompostgresql.conf, по сравнению с дефолтным
```bash
listen_addresses = '*'
log_timezone = 'Europe/Moscow'
```
Запускаем через `docker compose up -d`, добавляем тестовые данные в БД `bingo prepare_db`.
<br><br>
### Этап 2
**Запуск бинарника:**<br>
Пробуем запустить сервер
```bash
bingo run_server
```
Видим ошибку с логами, делаем strace
```bash
strace bingo run_server
```
Находим несуществующий путь и создаем папку
```bash
mkdir -p /opt/bongo/logs/6561f4ba98/
touch /opt/bongo/logs/6561f4ba98/main.log
chmod 777 /opt/bongo/logs/6561f4ba98/main.log
```
Пробуем запустить
```bash
bingo run_server
```
- [X] Запуск приложения
Узнаем какой порт прослушивает Bingo после успешного его запуска
```bash
ss -ltnp
LISTEN    0    128    *:19225    *:*    users:(("bingo",pid=6849,fd=9))
```
Сделаем тест текущего приложения
- [X] GET /api/movie работает корректно
- [X] GET /api/customer работает корректно
- [X] GET /api/session работает корректно
<br><br>
### Этап 3
**Упаковка сервера в контейнер:**<br>
Создадим Dockerfile
```bash
vim Dockerfile
```
Берем в основу Ubuntu, скачиваем в неё Bingo, и запускаем
```Dockerfile
FROM ubuntu

WORKDIR /opt/bingo

RUN apt update && \
    apt upgrade -y && \
    apt install -y wget telnet curl tzdata && \
    apt autoremove -y && \
    wget https://storage.yandexcloud.net/final-homework/bingo && \
    mv bingo /bin/bingo && \
    chmod 755 /bin/bingo && \
    wget https://raw.githubusercontent.com/d3adwolf/young-yandex-public/main/config.yaml && \
    adduser user --shell /bin/bash && \
    usermod -aG sudo user && \
    mkdir -p /opt/bongo/logs/6561f4ba98/ && \
    touch /opt/bongo/logs/6561f4ba98/main.log && \
    chmod 777 -R /opt/bongo/

USER user

CMD ["bingo", "run_server"]
```
Собираем build
```bash
docker build --no-cache -t <USER>/bingo:<TAG> .
```
Логинемся в Docker Hub
```bash
docker login
```
Пушим актуальную версию
```bash
docker push <USER>/bingo:<TAG>
```
Всё, рабочий образ лежит в [репозитории](https://hub.docker.com/repository/docker/d3adwolf/bingo/general) DockerHub'а
<br><br>
### Этап 4
**Упаковка связанной инфраструктуры в docker-compose:**<br>
Создадим основной docker-compose
```bash
vim docker-compose.yaml
```
Запускать docker-compose можно командой
```bash
docker compose up -d
```
Но у нас две ноды, поэтому делаем два разных файла
```bash
mv docker-compose.yaml node-01.yaml
cp node-01.yaml node-02.yaml
```
Запускаем docker-compose на первой, и потом на второй ноде
```bash
docker compose -f node-<NUMBER>.yaml up -d
```
Выключать контейнеры через
```bash
docker compose -f node-<NUMBER>.yaml down
```
В каждом docker-compose, где есть поддержка `timezone` и `locale`, укажем наш регион, для правильного времени в логах
```yaml
environment:
      - LANG=C.UTF-8
      - TZ=Europe/Moscow
```
`LANG=C.UTF-8` выдает 24-часовой формат, а `TZ=Europe/Moscow` наше время
<br><br>
### Этап 5
**Настройка балансера:**<br>
Создадим docker-compose для Nginx ноды
```bash
vim balancer.yaml
```
Создадим конфиг для Nginx
```bash
vim nginx.conf
```
Здесь мы указываем две ноды для балансера
```nginx
upstream backend {
        server 192.168.0.66:19225;
        server 192.168.0.67:19225;
    }
```
Указываем виртуальный сайт для трафика, в нем как раз работает балансер, не забываем про proxy_next_upstream, он перекинет трафик на другую ноду, если одна нода упадёт
```nginx
location / {
            proxy_pass http://backend;
	    proxy_next_upstream error timeout http_502 http_504;
        }
```
- [X] GET /db_dummy соотвествует SLA
- [X] GET /api/movie/{id} работает корректно
- [X] GET /api/customer/{id} работает корректно
- [X] GET /api/session/{id} работает корректно
- [X] Отказоустойчивость 1
- [X] Отказоустойчивость 2
- [X] Отказоустойчивость 3
<br><br>
### Этап 6
**Настройка домена и HTTPS:**<br>
1. Оформим домен на [REG.ru](https://www.reg.ru/), пропишем там A, AAAA записи.
2. 	a. Лично я зайду на свой продовый контейнер [Nginx Proxy Manager](https://proxy.foreverfunface.ru/) и добавлю туда домен с REG.ru, там же подключу SSL сертификаты через Let's Encrypt
	b. Либо настроить в Nginx SSL через CertBot
- [X] Есть https
<br><br>
### Финальный этап
**Запуск полной инфраструктуры:**
<br>Структура файлов на каждой ноде
```bash
user@192.168.0.66
|-- custompostgresql.conf
`-- node-01.yaml
```
```bash
user@192.168.0.67
|-- custompostgresql.conf
`-- node-02.yaml
```
```bash
user@192.168.0.68
|-- nginx.conf
`-- nginx.yaml
```
Запуск контейнеров через
```bash
dokcer compose -f <NAME>.yaml up -d
```
Скачать необходимые файлы можно с этого репозитория через
```
wget <URL>
```
или
```
git pull
```
Правильнее будет вариант с Git'ом
<br><br>
### Разное
**Нахождение мною всех кодов:**<br>
При любом успешном запуске сервера:
```bash
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
При запросе корневой страницы сайта (`/`):
```bash
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
- [X] Поход в корень
<br><br>
Да, я пытался найти в исходниках пасхалку, советы, но нашел код, который можно получить, заблочив Google домен:
```bash
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
```bash
netstat -anp | grep bingo
tcp        0      1 172.25.251.86:42506     8.8.8.8:80              SYN_SENT    74648/bingo
```
Эту команду выполняем вне контейнера, а в compose указываем сеть `host`, чтобы `iptables` хоста работал на сам контейнер:
```bash
iptables -t filter -A OUTPUT -d 8.8.8.8/32 -j REJECT
```
- [X] Гугл забанен 😄
<br><br>
```
Congratulations.
You were able to figure out why
the application is slow to start and fix it.
Here's a secret code that confirms that you did it.
--------------------------------------------------
code:         google_dns_is_not_http
--------------------------------------------------
```
- [X] Ускорен старт
<br><br>
**Оптимизация SQL-запросов:**<br>
Воспользоваться можно, как и SQL-клиентами, так и [pgadmin4](https://pgadmin.youngyandex.ru/)
Логин: `admin@admin.com`
Пароль: `root`

Построим индексы для сложного запроса на /api/session
```sql
CREATE INDEX customers_id_indx ON public.customers (id);
CREATE INDEX movies_id_indx ON public.movies (id DESC);
CREATE INDEX movies_name_indx ON public.movies ("name");
CREATE INDEX movies_year_indx ON public.movies ("year" DESC);
CREATE INDEX sessions_id_indx ON public.sessions (id DESC);
```
- [X] GET /api/session/{id} работает корректно
Проверим на всякий новые индексы
```sql
SELECT indexname, tablename FROM pg_indexes;
```
Проверили, отлично
<br><br>
**Оптимизация SQL-сервера:**<br>
Рекомендуемый конфиг взят с [PGtune](https://pgtune.leopard.in.ua/) для конкретно моих LXC контейнеров
```conf
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
Пока результатов в тесте это не принесло, нужно смотреть скоррость выполнения SQL-скриптов, но это уже после дедлайн, на момент дедлайна, тестировал на обычном конфиге без тюна
<br><br>
**Разборка docker-compose решений:**<br>
```yaml
healthcheck:
      test: ["CMD", "curl", "-s", "-f", "http://192.168.0.67:19225/ping"]
      start_period: 15s
      retries: 1
      timeout: 3s
      interval: 4s
```
Не каждое падение приложения вызывает `exit 1`, а вот `/ping` в случае проблем пишет, вместо `pong`, `I feel die`, именно поэтому лучше чекать `/ping`
<br>
```yaml
resources:
      limits:
        memory: 1024M
```
Я видел, что иногда выполняется переполнение памяти, особенно, без nginx-сервера, поэтому поставил лимит, после которого контейнер уходит в ребут
<br>
```yaml
environment:
      - PGUSER=postgres
network_mode: "host"
```
Чтобы исправить `psql: FATAL:  role "root" does not exist`, и БД была доступа снаружи
<br>
```yaml
autoheal:
      container_name: autoheal
      image: willfarrell/autoheal
```
Чтобы контейнеры перезапускались после `Unhealthy`, ибо это фича Docker Swarm'а
<br><br>
**Задачи под звездочкой:**<br>
```bash
curl http://youngyandex.ru
```
```
Hi. Accept my congratulations. You were able to launch this app...
```
- [X] HTTP без редиректа на HTTPS - по идее работает, но мой Nginx Proxy Manager не радует нормальной работой
<br>

**Чего не было сделано и почему:**<br>
- [ ] POST /api/session работает корректно - перестал срабатывать за час до дедлайна, ошибка была `proxy_cache_methods GET;` в `nginx.conf`
- [ ] Есть кеширование для GET /long_dummy - вероятно неправильно настроен Nginx конфиг, либо не хватает пару секунд для авто-тестирования
- [ ] HTTP3 - не работает в Nginx Proxy Manager, надо было сразу настраивать Nginx
- [ ] Мониторинг RPS и ошибок - в проде крутиться мониторинг LXC контейнеров через [Grafana](https://grafana.foreverfunface.ru/), отдельный на Prometheus не успел
- [ ] Автоматизировать развёртывание - идеальное видение:
<br>      a. Развертывание LXC в Proxmox через Terraform
<br>      b. Первоначальная настройка LXC через cloud-init
<br>      c. GitLab CI/CD для билда Docker Image
<br>      d. Мониторинг LXC, Docker, Nginx через node_exporter + Prometheus + Grafana
<br>      e. Скачивание Bash скрипта через Wget, который выполнит Terraform и Docker Compose
<br>      f. Автоматическая настройка нод по SSH через Ansible
<br><br>

**Завершил дедлайн на:**<br><br>
<img src="https://i.imgur.com/WS2cpGn.png" width="500"><br><br>
Получал ли я `POST /api/session работает корректно` и `Есть кеширование для GET /long_dummy`? - да.<br>Успел ли я к дедлайну? - нет.
