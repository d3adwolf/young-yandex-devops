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
