# 🛠️ Self - 个人工具集

> 个人的一些小脚本 & 小工具，提升开发效率

---

## 📦 项目结构

```
self/
├── shell/          # Shell 脚本工具
│   └── autodeploy.sh   # 数据库自动部署脚本
└── docker/         # Docker 相关工具
    └── Dockerfile      # 开发环境镜像
```

---

## 🚀 Shell 工具

### autodeploy.sh - 数据库自动部署脚本

一键部署 MySQL、Redis、MongoDB 数据库容器，支持交互式配置和命令行参数。

#### ✨ 特性

- 🎯 **可选安装** - 自由选择需要安装的数据库组件
- 🔧 **交互式配置** - 支持自定义版本、端口、密码等配置
- 📦 **一键部署** - 自动拉取镜像、创建配置、启动服务
- 🔍 **智能检测** - 自动检测端口占用、等待服务就绪
- 📝 **配置持久化** - 自动生成配置文件和 docker-compose.yml

#### 📖 使用方法

**方式一：在线运行（推荐）**

```bash
# 交互式选择组件
bash <(curl -sSL https://raw.githubusercontent.com/hakazeharuka/self/main/shell/autodeploy.sh)

# 指定安装组件
bash <(curl -sSL https://raw.githubusercontent.com/hakazeharuka/self/main/shell/autodeploy.sh) -m -r
```

**方式二：本地运行**

```bash
# 克隆仓库
git clone https://github.com/hakazeharuka/self.git && cd self/shell

# 添加执行权限
chmod +x autodeploy.sh

# 运行脚本
./autodeploy.sh
```

#### 🎮 命令行参数

| 参数            | 说明         |
| --------------- | ------------ |
| `-h, --help`    | 显示帮助信息 |
| `-m, --mysql`   | 安装 MySQL   |
| `-r, --redis`   | 安装 Redis   |
| `-g, --mongodb` | 安装 MongoDB |
| `-a, --all`     | 安装所有组件 |

#### 📝 使用示例

```bash
# 交互式选择（默认）
./autodeploy.sh

# 只安装 MySQL
./autodeploy.sh -m

# 安装 MySQL 和 Redis
./autodeploy.sh -m -r

# 安装 MySQL 和 MongoDB
./autodeploy.sh --mysql --mongodb

# 安装全部组件
./autodeploy.sh --all
```

#### 🖥️ 运行截图

```
╔══════════════════════════════════════════════╗
║        Database Docker 自动化部署向导        ║
╚══════════════════════════════════════════════╝

  提示: 直接按回车使用 [方括号] 中的默认值

  ── 选择要安装的组件 ──

  安装 MySQL？(Y/n) [Y]:
  安装 Redis？(Y/n) [Y]:
  安装 MongoDB？(Y/n) [Y]: n

  已选择安装:
    ✓ MySQL
    ✓ Redis
```

---

## 🐳 Docker 工具

### Dockerfile - 多语言开发环境

> 感谢 [jelin-sh](https://blog.jelin-sh.com/archives/based-on-docker-s-c-z2rbvla) 提供参考

基于 Ubuntu 22.04 的全能开发环境镜像，集成多种编程语言环境。

#### ✨ 集成环境

| 语言          | 描述             |
| ------------- | ---------------- |
| 🔷 **C/C++**  | GCC 编译器工具链 |
| 🐹 **Go**     | Golang 开发环境  |
| 🐍 **Python** | Python 运行环境  |
| 🦀 **Rust**   | Rust 开发工具链  |

#### 📖 使用方法

```bash
# 克隆仓库
git clone https://github.com/hakazeharuka/self.git && cd self

# 构建镜像
cd docker && docker buildx build . -t your-username/dev-env:latest

# 运行容器
docker run -itd \
  -v /workspace:/workspace \
  -p 2222:22 \
  your-username/dev-env:latest
```

#### 🔌 连接方式

```bash
# SSH 连接（端口 2222）
ssh root@localhost -p 2222
```

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/hakazeharuka">hakazeharuka</a>
</p>
