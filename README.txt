一: 容器启动注意点

端口映射

文件夹映射 (备份用. 必须) 容器内备份路径: /root/TABuild/DB-Client-Backup/


二: TA 相关的配置注意点都写在  Dockerfile 里面.


三: instantclient_11_2.ZIP 为定制的. 里面加了 exp imp sqlplus 命令.


三: 容器启动命令

docker run -d -p 2100:2100 \
-v /:/root/TABuild/DB-Client-Backup/ \
uhub.service.ucloud.cn/genesisfin/ta-xu:1.0


