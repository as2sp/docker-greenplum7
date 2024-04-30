FROM debian:bookworm-slim AS temp-image

RUN apt-get update && apt-get install -y \
        bison \
        ccache \
        cmake \
        curl \
        flex \
        gcc \
        g++ \
        git-core \
        inetutils-ping \
        iproute2 \
        krb5-admin-server \
        krb5-kdc \
        libapr1-dev \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libevent-dev \
        libkrb5-dev \
        libpam-dev \
        libperl-dev \
        libreadline-dev \
        libssl-dev \
        libxerces-c-dev \
        libxml2-dev \
        libyaml-dev \
        libzstd-dev \
        locales \
        net-tools \
        ninja-build \
        openssh-client \
        openssh-server \
        openssl \
        pkg-config \
        python3-dev \
        python3-pip \
        python3-psutil \
        python3-pygresql \
        python3-yaml \
        sudo \
        unzip \
        vim \
        wget \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/

RUN wget https://github.com/greenplum-db/gpdb/archive/refs/tags/7.1.0.zip && \
    unzip 7.1.0.zip -d /opt/

WORKDIR /opt/gpdb-7.1.0/

RUN echo "7.1.0 build" > ./VERSION && \
    ./configure --prefix=/usr/local/gpdb --with-perl --with-python --with-libxml --enable-gpfdist --with-gssapi \
        --with-zstd && \
    make -j $(nproc) && \
    make install

FROM debian:bookworm-slim AS final-image

RUN apt-get update && apt-get install -y \
        inetutils-ping \
        iproute2 \
        less \
        libcurl3-gnutls \
        libxerces-c3.2 \
        libxml2 \
        locales \
        make \
        net-tools \
        openssh-client \
        openssh-server \
        openssl \
        python3-psycopg2 \
        python3-psutil \
        python3-pygresql \
        python3-setuptools \
        rsync \
        sudo && \
    rm -rf /var/lib/apt/lists/*

COPY --from=temp-image /usr/local/gpdb/ /usr/local/gpdb/

ADD entrypoint.sh /

ARG SEG_NUM

RUN chmod +x /entrypoint.sh && \
    mkdir /data /data/gpcoordinator && \
    for i in $(seq 1 $SEG_NUM); do \
        mkdir /data/gpsegment$i; \
    done && \
    cp /usr/local/gpdb/docs/cli_help/gpconfigs/gpinitsystem_singlenode /data/ && \
    for i in $(seq 1 $SEG_NUM); do \
        sed -i "s/gpdata$i/data\/gpsegment$i/g" /data/gpinitsystem_singlenode; \
    done && \
    sed -i 's/gpcoordinator/data\/gpcoordinator/g' /data/gpinitsystem_singlenode && \
    sed -i "/^declare -a DATA_DIRECTORY=/c\declare -a DATA_DIRECTORY=($(for i in $(seq 1 ${SEG_NUM}); \
    do echo -n "/data/gpsegment$i "; done))" /data/gpinitsystem_singlenode && \
    useradd -md /home/gpadmin/ --shell /bin/bash gpadmin && \
    chown gpadmin -R /data && \
    echo "source /usr/local/gpdb/greenplum_path.sh" > /home/gpadmin/.bash_profile && \
    echo 'export PS1="\[\033[0;32m\][\[\033[0;32m\]\u@\[\033[0;32m\]\h \[\033[1;34m\]\W\[\033[0;37m\]]\$ "' \
    >> /home/gpadmin/.bash_profile && \
    echo 'export COORDINATOR_DATA_DIRECTORY="/data/gpcoordinator/gpsne-1/"'  >> /home/gpadmin/.bash_profile && \
    echo 'alias ll="ls -l"'  >> /home/gpadmin/.bash_profile && \
    chown gpadmin:gpadmin /home/gpadmin/.bash_profile && \
    su - gpadmin bash -c 'mkdir /home/gpadmin/.ssh' && \
    echo "gpadmin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "root ALL=NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir /run/sshd && \
    echo "set hlsearch" >> /home/gpadmin/.vimrc && \
    mv /usr/bin/hostname /usr/bin/hostname.bkp && \
    echo "echo localhost" > /usr/bin/hostname && \
    chmod +x /usr/bin/hostname && \
    echo localhost > /etc/hostname && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get autoremove -y

RUN su - gpadmin bash -c '\
    ssh-keygen -f /home/gpadmin/.ssh/id_rsa -t rsa -N "" && \
    cp /home/gpadmin/.ssh/id_rsa.pub /home/gpadmin/.ssh/authorized_keys && \
    chmod 600 /home/gpadmin/.ssh/authorized_keys && \
    cd /data/ && \
    echo "starting sshd ..." && \
    sudo /etc/init.d/ssh start && \
    sleep 2 && \
    ssh -o StrictHostKeyChecking=no localhost ls && \
    ssh -o StrictHostKeyChecking=no `hostname` ls && \
    source /home/gpadmin/.bash_profile && \
    echo localhost > /data/hostlist_singlenode && \
    sed -i "s/hostname_of_machine/localhost/g" /data/gpinitsystem_singlenode && \
    echo "gpssh-exkeys ..." && \
    gpssh-exkeys -f /data/hostlist_singlenode && \
    echo "gpinitsystem ..." && \
    gpinitsystem -ac gpinitsystem_singlenode && \
    echo "host all  all 0.0.0.0/0 trust" >> /data/gpcoordinator/gpsne-1/pg_hba.conf && \
    psql -d postgres -c "alter role gpadmin with password \$\$gppass\$\$" && \
    echo "gpstop ..." && \
    gpstop -a'

CMD ["/entrypoint.sh"]
