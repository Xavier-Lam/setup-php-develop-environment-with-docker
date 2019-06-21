# 将php开发环境部署在docker内

不使用WAMPP,不使用虚拟机,**优雅**方便快捷地在windows的docker下搭建多套php开发环境.

  - [安装并运行php container](#%E5%AE%89%E8%A3%85%E5%B9%B6%E8%BF%90%E8%A1%8Cphp-container)
  - [安装并运行nginx container](#%E5%AE%89%E8%A3%85%E5%B9%B6%E8%BF%90%E8%A1%8Cnginx-container)
  - [链接数据库cache等](#%E9%93%BE%E6%8E%A5%E6%95%B0%E6%8D%AE%E5%BA%93cache%E7%AD%89)
  - [构建网络连接容器](#%E6%9E%84%E5%BB%BA%E7%BD%91%E7%BB%9C%E8%BF%9E%E6%8E%A5%E5%AE%B9%E5%99%A8)
  - [使用IIS反代以便他人访问](#%E4%BD%BF%E7%94%A8IIS%E5%8F%8D%E4%BB%A3%E4%BB%A5%E4%BE%BF%E4%BB%96%E4%BA%BA%E8%AE%BF%E9%97%AE)
  - [使用](#%E4%BD%BF%E7%94%A8)
    - [以cli模式运行](#%E4%BB%A5cli%E6%A8%A1%E5%BC%8F%E8%BF%90%E8%A1%8C)
    - [xdebug调试](#xdebug%E8%B0%83%E8%AF%95)
    - [composer](#composer)
    - [psysh](#psysh)
  - [可能遇到的问题](#%E5%8F%AF%E8%83%BD%E9%81%87%E5%88%B0%E7%9A%84%E9%97%AE%E9%A2%98)
    - [挂载路径为空](#%E6%8C%82%E8%BD%BD%E8%B7%AF%E5%BE%84%E4%B8%BA%E7%A9%BA)
  - [参考链接](#%E5%8F%82%E8%80%83%E9%93%BE%E6%8E%A5)

## 安装并运行php container
建立一个Dockerfile,安装必要依赖

    FROM php:5.6-fpm
    LABEL maintainer="Xavier-Lam <Lam.Xavier@hotmail.com>"
    LABEL description="加装xdebug,redis,memcached,composer,psysh"

    # 安装依赖
    RUN apt-get update
    RUN apt-get install -y wget git libmemcached-dev zlib1g-dev
    RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev

    # 安装composer
    RUN wget https://getcomposer.org/installer -O /tmp/composer-setup.php
    RUN php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    RUN composer config -g repo.packagist composer https://packagist.phpcomposer.com

    # 用composer安装必要包
    RUN composer g require psy/psysh:@stable

    # 将composer的bin目录加入环境变量
    ENV PATH "$PATH:/root/.composer/vendor/bin/"

    # 安装拓展
    RUN docker-php-ext-install pdo pdo_mysql 
    RUN docker-php-ext-install -j$(nproc) iconv
    RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
    RUN docker-php-ext-install -j$(nproc) gd

    # 安装pecl拓展
    RUN pecl install xdebug-2.5.4
    RUN pecl install redis
    RUN pecl install memcached-2.2.0
    RUN pecl install memcache-2.2.7

    # 开启pecl拓展
    RUN docker-php-ext-enable redis memcached xdebug memcache

    # 配置xdebug
    RUN echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

    # 设置工作路径
    WORKDIR /data

构建并运行容器

    docker build . -t php:5.6-dev
    docker run -d -p 9000:9000 -v D:/projects:/data --name php-5.6 --restart unless-stopped php:5.6-dev

如在后期需要额外安装其他拓展或修改镜像,只需`FROM php:5.6-dev`构建即可


## 安装并运行nginx container

    docker pull nginx
    docker run -v D:/projects:/data -v D:/conf.d/:/etc/nginx/conf.d/ --name nginx -d -p 10000:80 --restart unless-stopped nginx
    docker exec -t nginx nginx -s reload

## 链接数据库cache等
以redis为例

    docker pull redis
    docker run --name redis -p 6379:6379 --restart unless-stopped redis

## 构建网络连接容器

    docker network create php-5.6
    docker network connect php-5.6 nginx
    docker network connect php-5.6 redis
    docker network connect php-5.6 php-5.6

在php的config中,redis的host直接用`redis`代替,nginx中fpm的host直接用`php-5.6`代替

## 使用IIS反代以便他人访问
用系统自带的IIS,也不用额外安装Apache了,优雅

参见这篇文章
> https://tecadmin.net/set-up-reverse-proxy-using-iis/

保留反向代理头部(不然host会掉)
> https://stackoverflow.com/a/14842856/4719118

对于反代的 X_FORWARDED_FOR 带有端口的问题 在ARR代理配置中取消勾选 Include TCP port from client IP
> https://docs.microsoft.com/en-us/iis/extensions/configuring-application-request-routing-arr/creating-a-forward-proxy-using-application-request-routing

## 使用
### 以cli模式运行
    docker exec -it php-5.6 php /path/to/your/file/in/your/docker

### xdebug调试
还没解决T T

### composer
    docker exec -it php-5.6 composer install -d /path/to/your/project/
### psysh
    docker exec -it php-5.6 psysh

## 可能遇到的问题
### 挂载路径为空
可能是修改过开机密码等登陆凭据,在docker GUI的settings > Shared Drives 中Reset credentials 重新选择Shared 并Apply
> https://stackoverflow.com/questions/50018812/docker-for-windows-volumes-are-empty/50348492#50348492

我感觉我每次reboot都要重新执行这个操作...

## 参考链接
> https://www.pascallandau.com/blog/php-php-fpm-and-nginx-on-docker-in-windows-10/
> 
> https://hub.docker.com/_/php
