## Young Yandex DevOps 2023
Итоговый проект Young Yandex по направлению DevOps 2023 года. 

### Этап 0
**Изначальная инфраструктура**
Домашний сервер Dell R510 с Proxmox VE 8.0.4
```
Linux proxmox 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 GNU/Linux
```
Внутри LXC контейнер **yy-test** с ubuntu-23.04-standart_23.04-1_amd64
```
Linux yy-test 6.2.16-19-pve #1 SMP PREEMPT_DYNAMIC PMX 6.2.16-19 (2023-10-24T12:07Z) x86_64 x86_64 x86_64 GNU/Linux
```

### Этап 1
**Изучение и настройка бинарника**
```
wget https://storage.yandexcloud.net/final-homework/bingo
```
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
**Запуск бинарника**

Пробуем запустить сервер
```
bingo run_server
```

Видим ошибку с логами, делаем strace
```
strace bingo run_server
# mkdir /opt/bongo/logs/
# mkdir /opt/bongo/logs/6561f4ba98/
# touch /opt/bongo/logs/6561f4ba98/main.log
# chmod 777 /opt/bongo/logs/6561f4ba98/main.log
```

```
ss -ltnp
LISTEN    0    128    *:19225    *:*    users:(("bingo",pid=6849,fd=9))
```

### Этап 3
**Упаковка сервера в контейнер**

### Разное
**Нахождение всех кодов**<br>
`bingo run_server` > `yoohoo_server_launched`<br>
`curl http://ip:19225` > `index_page_is_awesome`<br>
`xxd bingo` > `google_dns_is_not_http`<br>
