#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 安装选项标志
INSTALL_MYSQL=false
INSTALL_REDIS=false
INSTALL_MONGODB=false
INSTALL_POSTGRESQL=false

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

ask_yes_no() {
    local prompt="$1"
    local default="$2"
    local varname="$3"
    local input
    echo -ne "  ${CYAN}${prompt}${NC} ${BOLD}[${default}]${NC}: "
    read -r input
    input="${input:-$default}"
    if [[ "$input" =~ ^[Yy]$ ]]; then
        eval "$varname=true"
    else
        eval "$varname=false"
    fi
}

select_components() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║        Database Docker 自动化部署向导        ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}提示: 直接按回车使用 [方括号] 中的默认值${NC}"
    echo ""
    
    echo -e "  ${BOLD}── 选择要安装的组件 ──${NC}"
    echo ""
    ask_yes_no "安装 MySQL？(Y/n)" "Y" INSTALL_MYSQL
    ask_yes_no "安装 Redis？(Y/n)" "Y" INSTALL_REDIS
    ask_yes_no "安装 MongoDB？(Y/n)" "Y" INSTALL_MONGODB
    ask_yes_no "安装 PostgreSQL？(Y/n)" "Y" INSTALL_POSTGRESQL
    echo ""
    
    # 检查是否至少选择了一个组件
    if ! $INSTALL_MYSQL && ! $INSTALL_REDIS && ! $INSTALL_MONGODB && ! $INSTALL_POSTGRESQL; then
        log_error "至少需要选择一个组件进行安装！"
        exit 1
    fi
    
    echo -e "  ${GREEN}已选择安装:${NC}"
    $INSTALL_MYSQL && echo -e "    ${CYAN}✓ MySQL${NC}"
    $INSTALL_REDIS && echo -e "    ${CYAN}✓ Redis${NC}"
    $INSTALL_MONGODB && echo -e "    ${CYAN}✓ MongoDB${NC}"
    $INSTALL_POSTGRESQL && echo -e "    ${CYAN}✓ PostgreSQL${NC}"
    echo ""
}

interactive_config() {
    echo -e "  ${BOLD}── 通用配置 ──${NC}"
    ask "数据持久化根目录" "$(pwd)/database-data" BASE_DIR
    echo ""

    if $INSTALL_MYSQL; then
        echo -e "  ${BOLD}── MySQL 配置 ──${NC}"
        ask      "MySQL 版本"       "8"          MYSQL_VERSION
        ask      "MySQL 映射端口"   "3306"         MYSQL_PORT
        ask_password "MySQL root 密码"  "Root@123456"  MYSQL_ROOT_PASSWORD
        echo ""
        
        MYSQL_DATA_DIR="${BASE_DIR}/mysql/data"
        MYSQL_CONF_DIR="${BASE_DIR}/mysql/conf"
        MYSQL_LOG_DIR="${BASE_DIR}/mysql/logs"
    fi

    if $INSTALL_REDIS; then
        echo -e "  ${BOLD}── Redis 配置 ──${NC}"
        ask      "Redis 版本"       "8.2.0"          REDIS_VERSION
        ask      "Redis 映射端口"   "6379"         REDIS_PORT
        ask_password "Redis 访问密码"   "Redis@123456" REDIS_PASSWORD
        echo ""
        
        REDIS_DATA_DIR="${BASE_DIR}/redis/data"
        REDIS_CONF_DIR="${BASE_DIR}/redis/conf"
    fi
    
    if $INSTALL_MONGODB; then
        echo -e "  ${BOLD}── MongoDB 配置 ──${NC}"
        ask      "MongoDB 版本"       "latest"          MONGO_VERSION
        ask      "MongoDB 映射端口"   "27017"         MONGO_PORT
        echo ""
    fi

    if $INSTALL_POSTGRESQL; then
        echo -e "  ${BOLD}── PostgreSQL 配置 ──${NC}"
        ask      "PostgreSQL 版本"       "17"                PG_VERSION
        ask      "PostgreSQL 映射端口"   "5432"              PG_PORT
        ask_password "PostgreSQL 超级用户密码" "Postgres@123456"  PG_PASSWORD
        echo ""

        PG_DATA_DIR="${BASE_DIR}/postgresql/data"
    fi

    COMPOSE_PROJECT_NAME="auto-database"
}

confirm_config() {
    echo -e "  ${BOLD}── 配置摘要 ──${NC}"
    echo ""
    echo -e "  ${BOLD}通用${NC}"
    echo "    数据根目录:      ${BASE_DIR}"
    echo ""
    
    if $INSTALL_MYSQL; then
        echo -e "  ${BOLD}MySQL${NC}"
        echo "    版本:            ${MYSQL_VERSION}"
        echo "    端口:            ${MYSQL_PORT}"
        echo "    root 密码:       ${MYSQL_ROOT_PASSWORD}"
        echo "    数据目录:        ${MYSQL_DATA_DIR}"
        echo "    配置目录:        ${MYSQL_CONF_DIR}"
        echo "    日志目录:        ${MYSQL_LOG_DIR}"
        echo ""
    fi
    
    if $INSTALL_REDIS; then
        echo -e "  ${BOLD}Redis${NC}"
        echo "    版本:            ${REDIS_VERSION}"
        echo "    端口:            ${REDIS_PORT}"
        echo "    访问密码:        ${REDIS_PASSWORD}"
        echo "    数据目录:        ${REDIS_DATA_DIR}"
        echo "    配置目录:        ${REDIS_CONF_DIR}"
        echo ""
    fi
    
    if $INSTALL_MONGODB; then
        echo -e "  ${BOLD}MongoDB${NC}"
        echo "    版本:            ${MONGO_VERSION}"
        echo "    端口:            ${MONGO_PORT}"
        echo ""
    fi

    if $INSTALL_POSTGRESQL; then
        echo -e "  ${BOLD}PostgreSQL${NC}"
        echo "    版本:            ${PG_VERSION}"
        echo "    端口:            ${PG_PORT}"
        echo "    超级用户密码:    ${PG_PASSWORD}"
        echo "    数据目录:        ${PG_DATA_DIR}"
        echo ""
    fi
    
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

check_ports() {
    $INSTALL_MYSQL && check_port "$MYSQL_PORT" "MySQL"
    $INSTALL_REDIS && check_port "$REDIS_PORT" "Redis"
    $INSTALL_MONGODB && check_port "$MONGO_PORT" "MongoDB"
    $INSTALL_POSTGRESQL && check_port "$PG_PORT" "PostgreSQL"
}

create_dirs() {
    if $INSTALL_MYSQL; then
        mkdir -p "$MYSQL_DATA_DIR" "$MYSQL_CONF_DIR" "$MYSQL_LOG_DIR"
    fi
    if $INSTALL_REDIS; then
        mkdir -p "$REDIS_DATA_DIR" "$REDIS_CONF_DIR"
    fi
    if $INSTALL_POSTGRESQL; then
        mkdir -p "$PG_DATA_DIR"
    fi
    log_info "数据目录创建完成"
}

create_mysql_conf() {
    if ! $INSTALL_MYSQL; then
        return
    fi
    
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
    if ! $INSTALL_REDIS; then
        return
    fi
    
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
    local compose_content=""
    local services_to_check=""
    
    # 开始构建 compose 文件
    compose_content="
services:"

    # MySQL 服务配置
    if $INSTALL_MYSQL; then
        local abs_mysql_data abs_mysql_conf abs_mysql_log
        abs_mysql_data="$(cd "$MYSQL_DATA_DIR" && pwd)"
        abs_mysql_conf="$(cd "$MYSQL_CONF_DIR" && pwd)"
        abs_mysql_log="$(cd "$MYSQL_LOG_DIR" && pwd)"
        
        compose_content+="
  mysql:
    image: mysql:${MYSQL_VERSION}
    container_name: mysql
    restart: always
    ports:
      - \"${MYSQL_PORT}:3306\"
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
      test: [\"CMD\", \"mysqladmin\", \"ping\", \"-h\", \"localhost\", \"-u\", \"root\", \"-p${MYSQL_ROOT_PASSWORD}\"]
      interval: 10s
      timeout: 5s
      retries: 5"
    fi

    # Redis 服务配置
    if $INSTALL_REDIS; then
        local abs_redis_data abs_redis_conf
        abs_redis_data="$(cd "$REDIS_DATA_DIR" && pwd)"
        abs_redis_conf="$(cd "$REDIS_CONF_DIR" && pwd)"
        
        compose_content+="
  redis:
    image: redis:${REDIS_VERSION}
    container_name: redis
    restart: always
    ports:
      - \"${REDIS_PORT}:6379\"
    environment:
      TZ: Asia/Shanghai
    volumes:
      - ${abs_redis_data}:/data
      - ${abs_redis_conf}/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - database-network
    healthcheck:
      test: [\"CMD\", \"redis-cli\", \"-a\", \"${REDIS_PASSWORD}\", \"ping\"]
      interval: 10s
      timeout: 5s
      retries: 5"
    fi

    # MongoDB 服务配置
    if $INSTALL_MONGODB; then
        compose_content+="
  mongodb:
    image: mongodb/mongodb-community-server:${MONGO_VERSION}
    container_name: mongodb
    restart: always
    ports:
      - \"${MONGO_PORT}:27017\"
    environment:
      TZ: Asia/Shanghai
    networks:
      - database-network"
    fi

    # PostgreSQL 服务配置
    if $INSTALL_POSTGRESQL; then
        local abs_pg_data
        abs_pg_data="$(cd "$PG_DATA_DIR" && pwd)"

        compose_content+="
  postgresql:
    image: postgres:${PG_VERSION}
    container_name: postgresql
    restart: always
    ports:
      - \"${PG_PORT}:5432\"
    environment:
      POSTGRES_PASSWORD: ${PG_PASSWORD}
      TZ: Asia/Shanghai
      PGTZ: Asia/Shanghai
    volumes:
      - ${abs_pg_data}:/var/lib/postgresql
    networks:
      - database-network
    healthcheck:
      test: [\"CMD-SHELL\", \"pg_isready -U postgres\"]
      interval: 10s
      timeout: 5s
      retries: 5"
    fi

    # 网络配置
    compose_content+="

networks:
  database-network:
    driver: bridge
"

    echo "$compose_content" > docker-compose.yml
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
        local mysql_ok=true redis_ok=true mongo_ok=true pg_ok=true
        
        if $INSTALL_MYSQL; then
            mysql_ok=false
            docker exec mysql mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" &>/dev/null && mysql_ok=true
        fi
        
        if $INSTALL_REDIS; then
            redis_ok=false
            docker exec redis redis-cli -a "${REDIS_PASSWORD}" ping &>/dev/null && redis_ok=true
        fi
        
        if $INSTALL_MONGODB; then
            mongo_ok=false
            docker exec mongodb mongosh --port 27017 --eval "db.runCommand({ping:1})" &>/dev/null && mongo_ok=true
        fi

        if $INSTALL_POSTGRESQL; then
            pg_ok=false
            docker exec postgresql pg_isready -U postgres &>/dev/null && pg_ok=true
        fi

        if $mysql_ok && $redis_ok && $mongo_ok && $pg_ok; then
            echo ""
            local ready_services=""
            $INSTALL_MYSQL && ready_services+="MySQL "
            $INSTALL_REDIS && ready_services+="Redis "
            $INSTALL_MONGODB && ready_services+="MongoDB "
            $INSTALL_POSTGRESQL && ready_services+="PostgreSQL "
            log_info "${ready_services}均已就绪"
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
    local filter_args=""
    $INSTALL_MYSQL && filter_args+="--filter name=mysql "
    $INSTALL_REDIS && filter_args+="--filter name=redis "
    $INSTALL_MONGODB && filter_args+="--filter name=mongodb "
    $INSTALL_POSTGRESQL && filter_args+="--filter name=postgresql "
    docker ps $filter_args --format "    {{.Names}}	{{.Status}}	{{.Ports}}" 2>/dev/null || true
    echo ""

    echo -e "  ${BOLD}连接信息${NC}"
    $INSTALL_MYSQL && echo "    MySQL   →  localhost:${MYSQL_PORT}  用户: root  密码: ${MYSQL_ROOT_PASSWORD}"
    $INSTALL_REDIS && echo "    Redis   →  localhost:${REDIS_PORT}  密码: ${REDIS_PASSWORD}"
    $INSTALL_MONGODB && echo "    MongoDB →  localhost:${MONGO_PORT}"
    $INSTALL_POSTGRESQL && echo "    PostgreSQL →  localhost:${PG_PORT}  用户: postgres  密码: ${PG_PASSWORD}"
    echo ""

    echo -e "  ${BOLD}常用命令${NC}"
    if $INSTALL_MYSQL; then
        echo "    进入 MySQL:         docker exec -it mysql mysql -uroot -p'${MYSQL_ROOT_PASSWORD}'"
        echo "    查看 MySQL 日志:    docker logs -f mysql"
    fi
    if $INSTALL_REDIS; then
        echo "    进入 Redis:         docker exec -it redis redis-cli -a '${REDIS_PASSWORD}'"
        echo "    查看 Redis 日志:    docker logs -f redis"
    fi
    if $INSTALL_MONGODB; then
        echo "    进入 MongoDB:       docker exec -it mongodb mongosh --port 27017"
        echo "    查看 MongoDB 日志:  docker logs -f mongodb"
    fi
    if $INSTALL_POSTGRESQL; then
        echo "    进入 PostgreSQL:    docker exec -it postgresql psql -U postgres"
        echo "    查看 PostgreSQL 日志: docker logs -f postgresql"
    fi
    echo "    停止服务:           docker compose -p ${COMPOSE_PROJECT_NAME} down"
    echo "    停止并删除数据:     docker compose -p ${COMPOSE_PROJECT_NAME} down -v && rm -rf ${BASE_DIR}"
    echo ""
}

show_help() {
    echo ""
    echo -e "${BOLD}Database Docker 自动化部署脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -m, --mysql         只安装 MySQL"
    echo "  -r, --redis         只安装 Redis"
    echo "  -g, --mongodb       只安装 MongoDB"
    echo "  -p, --postgresql    只安装 PostgreSQL"
    echo "  -a, --all           安装所有组件 (MySQL + Redis + MongoDB + PostgreSQL)"
    echo ""
    echo "示例:"
    echo "  $0                  交互式选择要安装的组件"
    echo "  $0 -m               只安装 MySQL"
    echo "  $0 -m -r            安装 MySQL 和 Redis"
    echo "  $0 --all            安装所有组件"
    echo ""
}

parse_args() {
    local has_component_flag=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--mysql)
                INSTALL_MYSQL=true
                has_component_flag=true
                shift
                ;;
            -r|--redis)
                INSTALL_REDIS=true
                has_component_flag=true
                shift
                ;;
            -g|--mongodb)
                INSTALL_MONGODB=true
                has_component_flag=true
                shift
                ;;
            -p|--postgresql)
                INSTALL_POSTGRESQL=true
                has_component_flag=true
                shift
                ;;
            -a|--all)
                INSTALL_MYSQL=true
                INSTALL_REDIS=true
                INSTALL_MONGODB=true
                INSTALL_POSTGRESQL=true
                has_component_flag=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有通过命令行指定组件，则进入交互式选择
    if ! $has_component_flag; then
        select_components
    else
        echo ""
        echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}║        Database Docker 自动化部署向导        ║${NC}"
        echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}已选择安装:${NC}"
        $INSTALL_MYSQL && echo -e "    ${CYAN}✓ MySQL${NC}"
        $INSTALL_REDIS && echo -e "    ${CYAN}✓ Redis${NC}"
        $INSTALL_MONGODB && echo -e "    ${CYAN}✓ MongoDB${NC}"
        $INSTALL_POSTGRESQL && echo -e "    ${CYAN}✓ PostgreSQL${NC}"
        echo ""
    fi
}

main() {
    parse_args "$@"
    interactive_config
    confirm_config
    check_docker
    check_ports
    create_dirs
    create_mysql_conf
    create_redis_conf
    create_compose_file
    start_services
    print_result
}

main "$@"