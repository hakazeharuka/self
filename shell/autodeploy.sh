#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[√] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[!] $1${NC}"; }
log_error() { echo -e "${RED}[x] $1${NC}"; }

ask() {
    local prompt="$1"
    local default="$2"
    local varname="$3"
    local input
    echo -ne "  ${CYAN}${prompt}${NC} ${BOLD}[${default}]${NC}: "
    read -r input
    eval "$varname='${input:-$default}'"
}

ask_password() {
    local prompt="$1"
    local default="$2"
    local varname="$3"
    local input
    echo -ne "  ${CYAN}${prompt}${NC} ${BOLD}[${default}]${NC}: "
    read -r input
    eval "$varname='${input:-$default}'"
}

interactive_config() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║        Database Docker 自动化部署向导        ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}提示: 直接按回车使用 [方括号] 中的默认值${NC}"
    echo ""


    echo -e "  ${BOLD}── 通用配置 ──${NC}"
    ask "数据持久化根目录" "$(pwd)/database-data" BASE_DIR
    echo ""

    echo -e "  ${BOLD}── MySQL 配置 ──${NC}"
    ask      "MySQL 版本"       "8"          MYSQL_VERSION
    ask      "MySQL 映射端口"   "3306"         MYSQL_PORT
    ask_password "MySQL root 密码"  "Root@123456"  MYSQL_ROOT_PASSWORD
    echo ""

    echo -e "  ${BOLD}── Redis 配置 ──${NC}"
    ask      "Redis 版本"       "8.2.0"          REDIS_VERSION
    ask      "Redis 映射端口"   "6379"         REDIS_PORT
    ask_password "Redis 访问密码"   "Redis@123456" REDIS_PASSWORD
    echo ""
    
    echo -e "  ${BOLD}── MongoDB 配置 ──${NC}"
    ask      "MongoDB 版本"       "latest"          MONGO_VERSION
    ask      "MongoDB 映射端口"   "27017"         MONGO_PORT
    echo ""

    MYSQL_DATA_DIR="${BASE_DIR}/mysql/data"
    MYSQL_CONF_DIR="${BASE_DIR}/mysql/conf"
    MYSQL_LOG_DIR="${BASE_DIR}/mysql/logs"
    REDIS_DATA_DIR="${BASE_DIR}/redis/data"
    REDIS_CONF_DIR="${BASE_DIR}/redis/conf"
    COMPOSE_PROJECT_NAME="auto-database"
}

confirm_config() {
    echo -e "  ${BOLD}── 配置摘要 ──${NC}"
    echo ""
    echo -e "  ${BOLD}通用${NC}"
    echo "    数据根目录:      ${BASE_DIR}"
    echo ""
    echo -e "  ${BOLD}MySQL${NC}"
    echo "    版本:            ${MYSQL_VERSION}"
    echo "    端口:            ${MYSQL_PORT}"
    echo "    root 密码:       ${MYSQL_ROOT_PASSWORD}"
    echo "    数据目录:        ${MYSQL_DATA_DIR}"
    echo "    配置目录:        ${MYSQL_CONF_DIR}"
    echo "    日志目录:        ${MYSQL_LOG_DIR}"
    echo ""
    echo -e "  ${BOLD}Redis${NC}"
    echo "    版本:            ${REDIS_VERSION}"
    echo "    端口:            ${REDIS_PORT}"
    echo "    访问密码:        ${REDIS_PASSWORD}"
    echo "    数据目录:        ${REDIS_DATA_DIR}"
    echo "    配置目录:        ${REDIS_CONF_DIR}"
    echo ""
    echo -e "  ${BOLD}MongoDB${NC}"
    echo "    版本:            ${MONGO_VERSION}"
    echo "    端口:            ${MONGO_PORT}"
    echo ""
    echo -e "  ${BOLD}────────────────────────────────────────────${NC}"
    echo ""

    local confirm
    echo -ne "  ${CYAN}确认以上配置并开始部署？(Y/n)${NC}: "
    read -r confirm
    confirm="${confirm:-Y}"
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "已取消部署"
        exit 0
    fi
    echo ""
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker！"
        exit 1
    fi
    if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose！"
        exit 1
    fi
    log_info "Docker 环境检查通过"
}

check_port() {
    local port=$1 name=$2
    if ss -tlnp 2>/dev/null | grep -q ":${port} " || \
       netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
        log_error "端口 ${port} 已被占用，请为 ${name} 更换端口！"
        exit 1
    fi
}

create_dirs() {
    mkdir -p "$MYSQL_DATA_DIR" "$MYSQL_CONF_DIR" "$MYSQL_LOG_DIR"
    mkdir -p "$REDIS_DATA_DIR" "$REDIS_CONF_DIR"
    log_info "数据目录创建完成"
}

create_mysql_conf() {
    cat > "$MYSQL_CONF_DIR/my.cnf" <<'EOF'

[mysqld]
host-cache-size=0
skip-name-resolve
datadir=/var/lib/mysql
socket=/var/run/mysqld/mysqld.sock
secure-file-priv=/var/lib/mysql-files
user=mysql
default-time-zone=+08:00
character-set-server=utf8mb4
pid-file=/var/run/mysqld/mysqld.pid

[client]
socket=/var/run/mysqld/mysqld.sock

!includedir /etc/mysql/conf.d/
EOF
    log_info "MySQL 配置文件已写入 ${MYSQL_CONF_DIR}/my.cnf"
}

create_redis_conf() {
    cat > "$REDIS_CONF_DIR/redis.conf" <<EOF
bind 0.0.0.0
protected-mode yes
port 6379
requirepass ${REDIS_PASSWORD}

save 900 1
save 300 10
save 60 10000
dbfilename dump.rdb
dir /data

appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

maxmemory 256mb
maxmemory-policy allkeys-lru
loglevel notice
EOF
    log_info "Redis 配置文件已写入 ${REDIS_CONF_DIR}/redis.conf"
}

create_compose_file() {
    local abs_mysql_data abs_mysql_conf abs_mysql_log abs_redis_data abs_redis_conf
    abs_mysql_data="$(cd "$MYSQL_DATA_DIR" && pwd)"
    abs_mysql_conf="$(cd "$MYSQL_CONF_DIR" && pwd)"
    abs_mysql_log="$(cd "$MYSQL_LOG_DIR" && pwd)"
    abs_redis_data="$(cd "$REDIS_DATA_DIR" && pwd)"
    abs_redis_conf="$(cd "$REDIS_CONF_DIR" && pwd)"

    cat > docker-compose.yml <<EOF

services:
  mysql:
    image: mysql:${MYSQL_VERSION}
    container_name: mysql
    restart: always
    ports:
      - "${MYSQL_PORT}:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      TZ: Asia/Shanghai
    volumes:
      - ${abs_mysql_data}:/var/lib/mysql
      - ${abs_mysql_conf}/my.cnf:/etc/my.cnf
      - ${abs_mysql_log}:/var/log/mysql
    networks:
      - database-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:${REDIS_VERSION}
    container_name: redis
    restart: always
    ports:
      - "${REDIS_PORT}:6379"
    environment:
      TZ: Asia/Shanghai
    volumes:
      - ${abs_redis_data}:/data
      - ${abs_redis_conf}/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - database-network
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
  mongodb:
    image: mongodb/mongodb-community-server:${MONGO_VERSION}
    container_name: mongodb
    restart: always
    ports:
      - "${MONGO_PORT}:27017"
    environment:
      TZ: Asia/Shanghai
    networks:
      - database-network
     

networks:
  database-network:
    driver: bridge
EOF
    log_info "docker-compose.yml 生成完成"
}

start_services() {
    log_info "正在拉取镜像并启动服务（首次可能需要几分钟）..."
    if command -v docker compose &> /dev/null; then
        docker compose -p "$COMPOSE_PROJECT_NAME" up -d
    else
        docker-compose -p "$COMPOSE_PROJECT_NAME" up -d
    fi

    echo ""
    log_info "等待服务就绪..."
    local max_wait=30
    local waited=0
    while [ $waited -lt $max_wait ]; do
        local mysql_ok=false redis_ok=false mongo_ok=false
        docker exec mysql mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" &>/dev/null && mysql_ok=true
        docker exec redis redis-cli -a "${REDIS_PASSWORD}" ping &>/dev/null && redis_ok=true
        docker exec mongodb mongosh --port 27017 &>/dev/null && mongo_ok=true
        if $mysql_ok && $redis_ok && $mongo_ok; then
            echo ""
            log_info "MySQL、Redis、MongoDB 均已就绪"
            return 0
        fi
        echo -ne "\r  等待中... ${waited}s / ${max_wait}s"
        sleep 2
        waited=$((waited + 2))
    done
    echo ""
    log_warn "等待超时，服务可能仍在启动中，请稍后手动检查"
}

print_result() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                  部署完成                    ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "  ${BOLD}容器状态${NC}"
    docker ps --filter "name=mysql" --filter "name=redis" --filter "name=mongodb" \
        --format "    {{.Names}}	{{.Status}}	{{.Ports}}" 2>/dev/null || true
    echo ""

    echo -e "  ${BOLD}连接信息${NC}"
    echo "    MySQL   →  localhost:${MYSQL_PORT}  用户: root  密码: ${MYSQL_ROOT_PASSWORD}"
    echo "    Redis   →  localhost:${REDIS_PORT}  密码: ${REDIS_PASSWORD}"
    echo "    MongoDB →  localhost:${MONGO_PORT}" 
    echo ""

    echo -e "  ${BOLD}常用命令${NC}"
    echo "    进入 MySQL:         docker exec -it mysql mysql -uroot -p'${MYSQL_ROOT_PASSWORD}'"
    echo "    进入 Redis:         docker exec -it redis redis-cli -a '${REDIS_PASSWORD}'"
    echo "    进入 MongoDB:       docker exec -it mongodb mongosh --port 27017"
    echo "    查看 MySQL 日志:    docker logs -f mysql"
    echo "    查看 Redis 日志:    docker logs -f redis"
    echo "    查看 MongoDB 日志:  docker logs -f mongodb"
    echo "    停止服务:           docker compose -p ${COMPOSE_PROJECT_NAME} down"
    echo "    停止并删除数据:     docker compose -p ${COMPOSE_PROJECT_NAME} down -v && rm -rf ${BASE_DIR}"
    echo ""
}

main() {
    interactive_config
    confirm_config
    check_docker
    check_port "$MYSQL_PORT" "MySQL"
    check_port "$REDIS_PORT" "Redis"
    check_port "$MONGO_PORT" "MongoDB"
    create_dirs
    create_mysql_conf
    create_redis_conf
    create_compose_file
    start_services
    print_result
}

main