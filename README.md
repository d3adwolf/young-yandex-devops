## Young Yandex DevOps 2023
Итоговый проект Young Yandex по направлению DevOps 2023 года. 

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
Доступ в ресурсы сервера через обратный прокси [Nginx Proxy Manager](https://proxy.foreverfunface.ru)

### Этап 1
**Изучение и настройка бинарника:**
Скачиваем приложение (бинарник), основанный на [Cobra](https://github.com/spf13/cobra)
```
wget https://storage.yandexcloud.net/final-homework/bingo
```
Сделаем бинарник исполняемым в любой точке системы, будто мы его поставили через `apt`, создадим пользователя, чтобы соответствовать правильному подходу по ИБ, да и из под root-а не запуститься.
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
# mkdir /opt/bingo/
# vi /opt/bingo/config.yaml
```
Указываем свою почту: f3.d3ad.wolf@yandex.ru

Для удобства запустим БД сразу в Docker, установим его по инструкции:<br>
[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) и [Linux post-installation steps for Docker Engine](https://docs.docker.com/engine/install/linux-postinstall/)

Теперь ставим PostreSQL:
Для этого я нашел в интернете готовый docker-compose.yaml, он будет в /local в ГитХабе, на данный момент изменять его не нужно.
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
# mkdir -p /opt/bongo/logs/6561f4ba98/
# touch /opt/bongo/logs/6561f4ba98/main.log
# chmod 777 /opt/bongo/logs/6561f4ba98/main.log
```

```
ss -ltnp
LISTEN    0    128    *:19225    *:*    users:(("bingo",pid=6849,fd=9))
```

### Этап 3
**Упаковка сервера в контейнер:**

### Разное
**Нахождение мною всех кодов:**
При любом запуске сервера:
```
bingo run_server
```
`yoohoo_server_launched`<br><br>
При запросе корневой страницы сайта (`index.html`):
```
curl http://ip:19225
```
`index_page_is_awesome`<br><br>
Да, я пытался найти в исходниках пасхалку, советы, но нашел код, который можно получить заблочив Google домен где-то:
```
xxd bingo
```
`google_dns_is_not_http`<br><br>

sudo iptables -t filter -A OUTPUT -d 8.8.8.8/32 -j REJECT
netstat -anp | grep bingo
tcp        0      1 172.25.251.86:42506     8.8.8.8:80              SYN_SENT    74648/bingo
