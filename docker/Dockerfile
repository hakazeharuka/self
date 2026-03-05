FROM ubuntu:22.04
COPY ./sources.list /etc/apt/sources.list
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

ENV GO_VERSION=1.26.0
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH

ENV CMAKE_VERSION=4.2.3
ENV PYTHON_VERSION=3.12

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=$CARGO_HOME/bin:/root/.local/bin:$PATH

RUN set -eux \
    && apt-get update \
    && apt-get -yq upgrade \
    && apt-get -yq install \
        aptitude apt-rdepends bash build-essential ccache clang clang-tidy cppcheck curl doxygen diffstat gawk gdb git gnupg gperf iputils-ping \
        linux-tools-generic nano nasm ninja-build openssh-server openssl pkg-config python3 python-is-python3 spawn-fcgi net-tools iproute2 \
        sudo tini unzip valgrind wget zip texinfo gcc-multilib chrpath socat cpio xz-utils debianutils \
        patch perl tar rsync bc xterm whois software-properties-common apt-transport-https ca-certificates\
        dh-autoreconf apt-transport-https g++ graphviz xdot mesa-utils tclsh \
    && rm -rf /var/lib/apt/lists/*

# cmake
RUN set -eux \
    && wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh -q -O /tmp/cmake-install.sh \
    && chmod u+x /tmp/cmake-install.sh \
    && mkdir /opt/cmake-${CMAKE_VERSION} \
    && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-${CMAKE_VERSION} \
    && rm /tmp/cmake-install.sh \
    && ln -s /opt/cmake-${CMAKE_VERSION}/bin/* /usr/local/bin \
    && cmake --version 

# python
RUN set -eux \
    && wget https://astral.sh/uv/install.sh -q -O /tmp/uv.sh \
    && chmod u+x /tmp/uv.sh \
    && bash /tmp/uv.sh \
    && /root/.local/bin/uv python install ${PYTHON_VERSION} \
    && /root/.local/bin/uv --version

# go
RUN set -eux \
    && wget -q https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz \
    && mkdir -p ${GOPATH}/src ${GOPATH}/bin ${GOPATH}/pkg \
    && go version

# rust
RUN set -eux \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
       sh -s -- -y --default-toolchain stable --profile default \
    && chmod -R a+rw $RUSTUP_HOME $CARGO_HOME \
    && rustc --version

# ssh
RUN set -eux \
    && mkdir -p /var/run/sshd \
    && mkdir -p /root/.ssh \
    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
    && echo 'root:root' | chpasswd 

WORKDIR /workspace

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/usr/sbin/sshd","-D","-e"]