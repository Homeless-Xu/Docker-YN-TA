FROM frolvlad/alpine-glibc
# Alpine 默认不带 glibc 环境. 而 oracle 程序是用 glibc 编写出来的.
# 在 Alpine 下用 instantclient_11_2 必须安装 glibc 环境; 在 CentOS 这样的系统是默认支持的.


ENV LANG C.UTF-8
# 系统语言设置. 
# cat 不会乱码. vi 还是会的. TODO.....


RUN apk --update add tzdata \
	&& cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone
# 时区设置 "Asia/Shanghai" 改成你想要的时区 ✔✔✔


COPY . /root
RUN unzip /root/instantclient_11_2.zip -d /usr/lib && rm /root/instantclient_11_2.zip
RUN unzip /root/TABuild.zip -d /root && rm /root/TABuild.zip
# 上传 oracle 客户端文件. 里面包含了 exp imp sqlplus 等命令. 
# 上传 TA 项目文件..


RUN apk update && apk add libaio
ENV ORACLE_HOME=/usr/lib/instantclient_11_2
ENV LD_LIBRARY_PATH=/usr/lib/instantclient_11_2
ENV TNS_ADMIN=/usr/lib/instantclient_11_2
ENV PATH=/usr/lib/instantclient_11_2:${PATH}
ENV NLS_LANG="SIMPLIFIED CHINESE_CHINA.ZHS16GBK"
# 这个 NLS_LANG 必须设置. 不然备份会报错!!!❗❗❗️
# 不仅仅是 电脑连数据库的时候要设置 NLS_LANG 的. 执行备份命令的电脑 同样需要设置的!!!
# Oracle 相关环境变设置. 以及依赖安装.


RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
ENV JAVA_HOME /usr/lib/jvm/java-1.7-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.7-openjdk/jre/bin:/usr/lib/jvm/java-1.7-openjdk/bin
ENV JAVA_VERSION 7u151
ENV JAVA_ALPINE_VERSION 7.151.2.6.11-r0
RUN set -x \
	&& apk add --no-cache \
		openjdk7="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]
# JDK 1.7 安装配置


ENV SERV_HOME=/root/TABuild
# SERV_HOME 变量在Classpath 和 TA 的启动命令中都用到的!!!
ENV LIB_HOME=/root/TABuild/libs
# LIB_HOME 变量主要是给下面的Classpath 用的. 其他地方应该用不到的...
ENV CLASSPATH=.:${SERV_HOME}/bin:${LIB_HOME}/log4j-1.2.14.jar:${LIB_HOME}/jdom.jar:${LIB_HOME}/szhiisoRbc.jar:${LIB_HOME}/Oracle14.jar:${LIB_HOME}/TaStub.jar
# TA 最重要的 Classpath 变量.


#❗❗️TA 配置修改 - 数据库连接❗❗️
# vi /root/TABuild/conf/config.xml 
# dbUrl="jdbc:oracle:thin:@192.168.10.17:1521:YNTATEST" ➜ 改成你自己的.
# sed -i "s/原字符串/新字符串/g" 文件路径
# RUN sed -i "s/jdbc:oracle:thin:@10.10.91.251:1521:YNTA/jdbc:oracle:thin:@10.10.67.248:1521:YNTA/g" /root/TABuild/conf/config.xml


#❗❗️TA 配置修改 - 客户端备份 实例名修改❗❗️
# vi /root/TABuild/conf/config.xml  里面的 nativeUrlBak="YNTA"
# 去 oracle 客户端的 TNSNAMES.ora 配置就可以了... 


# ❗❗️ TA 备份路径映射.❗❗️
# TA 备份在服务器上. 需要 TA 后端服务器能运行 exp/imp 命令!!!
# 首先容器里面 备份路径必须存在.其次 备份文件应该保存到容器外面的.
# vi /root/TABuild/conf/config.xml  
# 默认路径: <bakpath path="/root/TABuild/DB-Client-Backup/" />


WORKDIR /root/TABuild
EXPOSE 2100

CMD ["/bin/sh","-c","$JAVA_HOME/bin/java -Xms128m -Xmx512m -Dconf.dir=$SERV_HOME/conf -DSERV_HOME=$SERV_HOME com.szhiiso.core.RemoteBeanCallService 2100 100"]
# 运行容器. 自动启动TA 程序.
# 实时查看容器日志:  docker logs <Contain ID> -f
