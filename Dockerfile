FROM openresty/openresty:alpine

# Install required build dependencies
RUN apk add --no-cache \
    git \
    gcc \
    musl-dev \
    postgresql-dev \
    lua5.1 \
    lua5.1-dev \
    luarocks5.1 \
    perl \
    make \
    bash \
    openssl \
    openssl-dev \
    curl \
    diffutils \
    grep \
    sed

# Install lua-resty-auto-ssl and dependencies using LuaRocks
RUN luarocks-5.1 install lua-resty-http && \
    luarocks-5.1 install shell-games 1.0.0-1 && \
    luarocks-5.1 install lua-resty-auto-ssl 0.13.1

# Install pgmoon and lua-resty-openssl using opm
RUN opm get leafo/pgmoon && \
    opm get fffonion/lua-resty-openssl && \
    opm get bungle/lua-resty-template

# Create directory for custom Lua modules and SSL
RUN mkdir -p /usr/local/openresty/lualib/custom && \
    mkdir -p /etc/letsencrypt/live && \
    mkdir -p /etc/resty-auto-ssl && \
    mkdir -p /etc/ssl && \
    chown -R nobody:nobody /etc/resty-auto-ssl

# Generate fallback SSL certificate
RUN openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj '/CN=sni-support-required-for-valid-ssl' \
        -keyout /etc/ssl/resty-auto-ssl-fallback.key \
        -out /etc/ssl/resty-auto-ssl-fallback.crt

# Clean up build dependencies if needed
RUN apk del gcc musl-dev

# Create nginx configuration directories
RUN mkdir -p /usr/local/openresty/nginx/conf/conf.d/domain_includes && \
    mkdir -p /usr/local/openresty/lualib/src

# Add nginx configuration files
COPY config/nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY config/nginx/conf.d/ /usr/local/openresty/nginx/conf/conf.d/

# Copy Lua source files
COPY src/lua/ /usr/local/openresty/lualib/src/

EXPOSE 80 443

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]