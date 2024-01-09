# Young Yandex DevOps 2023
**Language:** [🇷🇺](https://github.com/d3adwolf/young-yandex-devops/blob/main/README_RU.md) · 🇺🇸

The final project of Young Yandex's DevOps 2023. 
### Preface
> [!IMPORTANT]\
> Due to work and studies I had to devote only 4 days to the project, but all 4 days I sat non-stop at work.
## Preparatory phase
### Initial infrastructure

Home server **Dell R510** with [Proxmox VE 8.0.4](https://proxmox.foreverfunface.ru):
```bash
Linux proxmox 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 GNU/Linux
```
Inside the LXC container **yy-test** with **ubuntu-23.04-standart_23.04-1_amd64**:
```bash
Linux yy-test 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 x86_64 x86_64 x86_64 GNU/Linux
```
The server sites are accessed through the reverse proxy [Nginx Proxy Manager](https://proxy.foreverfunface.ru).
## Stage 1
### Learn and customize the binary
Download the application (binary) based on [Cobra](https://github.com/spf13/cobra):
```bash
wget https://storage.yandexcloud.net/final-homework/bingo
```
Make the binary executable anywhere in the system, as if we put it through `apt`, create a user to comply with the correct IS approach, and it won't run as root:
```bash
mv bingo /bin/
chmod 755 /bin/bingo
adduser user
usermod -aG sudo user
```
To start the server you need a config and a database with data.


See the location of the config:
```bash
strace bingo print_current_config
openat(AT_FDCWD, "/opt/bingo/config.yaml", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```
Let's start by recognizing the default config:
```bash
bingo print_default_config
```
Let's create the necessary folder and config:
```bash
mkdir /opt/bingo/
vi /opt/bingo/config.yaml
```
Specify your email: `f3.d3ad.wolf@yandex.ru`, and I uploaded the actual config to [public repository](https://github.com/d3adwolf/young-yandex-public):
- [X] In the config, the correct email


### Now let's install PostreSQL.


For convenience, let's run the database directly in Docker, install it according to the instructions:


[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) and [Linux post-installation steps for Docker Engine](https://docs.docker.com/engine/install/linux-postinstall/).


For this I found a ready-made docker-compose.yaml for PostreSQL on the internet, no need to modify it at that point, the part of the yaml file is like this:
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
Changes in custompostgresql.conf compared to the default:
```bash
listen_addresses = '*'
log_timezone = 'Europe/Moscow'
```
Run via `docker compose up -d`, add test data to the database **bingo prepare_db**.


## Stage 2
### Start the binary
Try to start the server:
```bash
bingo run_server
```
We see an error with logs, do strace:
```bash
strace bingo run_server
```
Find a path that doesn't exist and create a folder:
```bash
mkdir -p /opt/bongo/logs/6561f4ba98/
touch /opt/bongo/logs/6561f4ba98/main.log
chmod 777 /opt/bongo/logs/6561f4ba98/main.log
```
Try running:
```bash
bingo run_server
```
- [X] Start the application


Find out what port Bingo is listening on after successful startup:
```bash
ss -ltnp
LISTEN 0 128 *:19225 *:* users:((("bingo",pid=6849,fd=9)))
```
Let's test the current application:
- [X] GET /api/movie works correctly
- [X] GET /api/customer works correctly
- [X] GET /api/session works correctly
## Stage 3
### Pack the server into a container
Create a Dockerfile:
```bash
vim Dockerfile
```
Taking **Ubuntu** as a base, download Bingo and run it:
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
    touch /opt/bongo/logs/6561f4ba98/main.log&\
    chmod 777 -R /opt/bongo/


USER user


CMD ["bingo", "run_server"]
```
Build build:
```bash
docker build --no-cache -t <USER>/bingo:<TAG> .
```
Logging into Docker Hub:
```bash
docker login
```
Push the current version:
```bash
docker push <USER>/bingo:<TAG>
```
That's it, the working image is in DockerHub's [repository](https://hub.docker.com/r/d3adwolf/bingo).
## Stage 4
### Pack the linked infrastructure into docker-compose
Let's create a basic docker-compose:
```bash
vim docker-compose.yaml
```
You can run docker-compose with the command:
```bash
docker compose up -d
```
But we have two nodes, so we do two different files:
```bash
mv docker-compose.yaml node-01.yaml
cp node-01.yaml node-02.yaml
```
Run docker-compose on the first node and then on the second node:
```bash
docker compose -f node-<NUMBER>.yaml up -d
```
Shut down containers via:
```bash
docker compose -f node-<NUMBER>.yaml down
```
In every docker-compose that has support for `timezone` and `locale`, let's specify our region for the correct time in the logs:
```yaml
environment:
      - LANG=C.UTF-8
      - TZ=Europe/Moscow
```
``LANG=C.UTF-8` gives 24-hour format, and ``TZ=Europe/Moscow`` gives our time.

## Stage 5
### Configuring the balancer
Let's create a docker-compose for the Nginx node:
```bash
vim balancer.yaml
```
Create a config for Nginx:
```bash
vim nginx.conf
```
Here we specify two nodes for the balancer:
```nginx
upstream backend {
        server 192.168.0.66:19225;
        server 192.168.0.67:19225;
    }
```
Specify a virtual site for traffic, it's where the balancer works, don't forget about proxy_next_upstream, it will forward traffic to another node if one node goes down:
```nginx
location / {
            proxy_pass http://backend;
	    proxy_next_upstream error timeout http_502 http_504;
        }
```
- [X] GET /db_dummy complies with SLA
- [X] GET /api/movie/{id} works correctly
- [X] GET /api/customer/{id} works correctly
- [X] GET /api/session/{id} works correctly
- [X] Fault tolerance 1
- [X] Fault tolerance 2
- [X] Fault tolerance 3
## Stage 6
### Configuring Domain and HTTPS
1. Let's register the domain on [REG.ru](https://www.reg.ru/), write there `A` and `AAAA` records
2. 	a. I will go to my prod container [Nginx Proxy Manager](https://proxy.foreverfunface.ru/) and add the domain from REG.ru there, I will also connect SSL certificates via Let's Encrypt<br>
	b. Or configure SSL in Nginx via CertBot
- [X] There's https
## Final stage
### Running the full infrastructure
File structure on each node:
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
Running containers through:
```bash
dokcer compose -f <NAME>.yaml up -d
```
Download the necessary files from this repository via:
```bash
wget <URL>
```
or
```bash
git clone
```
The Git option would be more correct.
## Miscellaneous
### Finding all codes by me
On any successful server startup:
```bash
bingo run_server
```
```
My congratulations.
You were able to start the server.
Here's a secret code that confirms that you did it.
--------------------------------------------------
code: yoohoo_server_launched
--------------------------------------------------
```
When requesting the root page of the site (`/`):
```bash
curl http://ip:19225
```
```
Hi. Accept my congratulations. You were able to launch this app.
In the text of the task, you were given a list of urls and requirements for their work.
Get on with it. You can do it, you'll do it.
--------------------------------------------------
code: index_page_is_awesome
--------------------------------------------------
```
- [X] Root hike

Yeah, I was trying to find a passphrase in the source code, tips, but I found the code you can get by blocking the google domain:
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
Automatically or we're going the right way:
```bash
netstat -anp | grep bingo
tcp 0 1 172.25.251.86:42506 8.8.8.8.8:80 SYN_SENT 74648/bingo
```
Run this command outside the container, and specify the `host` network in compose so that the `iptables` of the host will work on the container itself:
```bash
iptables -t filter -A OUTPUT -d 8.8.8.8.8/32 -j REJECT
```
- [X] Google's banned 😄
- [X] Accelerated startfigure nodes over SSH via Ansible
```
Congratulations.
You were able to figure out why
the application is slow to start and fix it.
Here's a secret code that confirms that you did it.
--------------------------------------------------
code:         google_dns_is_not_http
--------------------------------------------------
```

### Optimization of SQL queries
You can use both SQL clients and [pgadmin4](https://www.pgadmin.org/download/pgadmin-4-container/).

Login: `admin@admin.com`

Password: `root`

Let's build indexes for a complex query on `/api/session`:
```sql
CREATE INDEX customers_id_indx ON public.customers (id);
CREATE INDEX movies_id_indx ON public.movies (id DESC);
CREATE INDEX movies_name_indx ON public.movies ("name");
CREATE INDEX movies_year_indx ON public.movies ("year" DESC);
CREATE INDEX sessions_id_indx ON public.sessions (id DESC);
```
- [X] GET /api/session/{id} works correctly
Let's check the new indexes just in case
```sql
SELECT indexname, tablename FROM pg_indexes;
```
Checked, great.

### SQL Server Optimization
The recommended config is taken from [PGtune](https://pgtune.leopard.in.ua/) for my LXC containers specifically:
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
So far it didn't bring any results in the test, we need to see the speed of SQL-scripts execution, but this is after the deadline, and at the time of the deadline I tested on a normal config without tuning.
### Docker-compose solutions disassembly
```yaml
healthcheck:
      test: ["CMD", "curl", "-s", "-f", "http://192.168.0.67:19225/ping"]
      start_period: 15s
      retries: 1
      timeout: 3s
      interval: 4s
```
Not every application crash causes `exit 1`, but `/ping` will write `I feel die` instead of `pong` in case of problems, that's why it's better to check `/ping`.
```yaml
resources:
      limits:
        memory: 1024M
```
I saw that sometimes memory overflow is performed, especially without nginx-server, so I set a limit after which the container goes into reboot.
```yaml
environment:
      - PGUSER=postgres
network_mode: "host"
```
To fix `psql: FATAL: role "root" does not exist`, and the database was accessed from outside.
```yaml
autoheal:
      container_name: autoheal
      image: willfarrell/autoheal
```
To make containers restart after ``Unhealthy``, for this is a Docker Swarm feature.
### Tasks under the asterisk
```bash
curl http://youngyandex.ru
```
```
Hi. Accept my congratulations. You were able to launch this app...
```
- [X] HTTP without redirect to HTTPS - supposedly works, but [Nginx Proxy Manager](https://proxy.foreverfunface.ru/) doesn't work stably


### What was not done and why
- [ ] POST /api/session works correctly - stopped working an hour before deadline, probably a bug in `nginx.conf`
- [ ] There is caching for GET /long_dummy - probably a bug in `nginx.conf`
- [ ] HTTP3 - doesn't work in [Nginx Proxy Manager](https://proxy.foreverfunface.ru), I should have configured Nginx right away
- [ ] RPS and error monitoring - there is monitoring of LXC containers via [Grafana](https://grafana.foreverfunface.ru/), but separate one on Nginx + PostgreSQL didn't have time for it
- [ ] Automate deployment - ideal vision:
<br> a. Deploying LXC in Proxmox via Terraform
<br> b. Initial configuration of the LXC via cloud-init
<br> c. GitLab CI/CD for the Docker Image build
<br> d. Monitoring LXC, Docker, Nginx via node_exporter + Prometheus + Grafana
<br> e. Downloading a Bash script via Wget that will execute Terraform and Docker Compose
<br> f. Automatically configure nodes over SSH via Ansible


### Completed the deadline with these results
<img src="https://i.imgur.com/WS2cpGn.png" width="500">


---
### Fixed after deadline.
- [X] POST /api/session works correctly - removed `proxy_cache_methods GET;` in `nginx.conf`
- [X] There is caching for GET /long_dummy - works fine in Nginx container, but caching is not configured in [Nginx Proxy Manager](https://proxy.foreverfunface.ru) because it is not properly supported there.
### Basic Automation
The team will download the script and it will already update the packages, download the current repository and install Docker:
```bash
wget https://raw.githubusercontent.com/d3adwolf/young-yandex-devops/main/deploy.sh && chmod +x deploy.sh && ./deploy.sh
```
Running docker-compose on three nodes:
```bash
docker compose -f node-01.yaml up -d
docker compose -f node-02.yaml up -d
docker compose -f balancer.yaml up -d
```
That's all for now, thanks for reading.
