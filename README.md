# self

个人的一些小脚本&amp;小工具

**shell/autodeploy.sh**

自动部署数据库脚本，使用以下命令运行

```shell
bash <(curl -sSL https://github.com/hakazeharuka/self/raw/refs/heads/main/shell/autodeploy.sh)
```

**docker/Dockerfile**

感谢https://blog.jelin-sh.com/archives/based-on-docker-s-c-z2rbvla提供参考

基于 Ubuntu 22.04 的开发环境，其中集成了C、C++、Go、Python、Rust的开发环境，使用以下命令构建镜像

```shell
git clone https://github.com/hakazeharuka/self.git && cd self
cd docker && docker buildx build . -t xxx/xxx:latest
```
