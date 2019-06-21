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