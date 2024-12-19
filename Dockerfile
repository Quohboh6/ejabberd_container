FROM ubuntu:latest

    # Install the necessary packages
RUN    apt-get update \
    && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y \
       curl \
       git \
       build-essential \
       autoconf \
       libpam0g-dev \
       libssl-dev \
       libexpat1-dev \
       libyaml-dev \
       libiconv-hook-dev \
       libsqlite3-dev \
       libmysqlclient-dev \
       libpq-dev \
       libgd-dev \
       libjpeg-dev \
       libpng-dev \
       erlang \
       erlang-dev \
       elixir \
    && rm -rf /var/lib/apt/lists/* \

    # Create ejabberd group with given GID
    # Create user ejabberd with given UID and bind to group ejabberd
    && groupadd -g 55001 ejabberd \
    && useradd -u 55001 -g ejabberd -m -s /usr/sbin/nologin ejabberd \
    && groupadd -g 55002 letsencrypt \
    && useradd -u 55002 -g 55002 -m -s /usr/sbin/nologin letsencrypt \
    && usermod -aG letsencrypt ejabberd \

    # Clone the ejabberd repository
    && git clone https://github.com/processone/ejabberd.git /ejabberd \
    # We go to the catalog and prepare the assembly
    && cd /ejabberd \
    && chmod +x autogen.sh && ./autogen.sh \
    && curl -LO https://github.com/erlang/rebar3/releases/download/3.24.0/rebar3 \
    && sha256sum rebar3 \
    && /usr/bin/mix local.rebar rebar3 ./rebar3 --force \
    && rm -f ./rebar3 \

    # Install Hex for Elixir (required for working with dependencies)
    && /usr/bin/mix local.hex --force \

    # Installing jiffy dependency
    && mix deps.update jiffy \

    # Installing the required Elixir dependencies
    && /usr/bin/mix deps.get \

    # Configure with PostgreSQL support and install
    && cd /ejabberd \
    && ./configure --prefix=/ --enable-all --enable-user=ejabberd \
    && make \
    && make install \

    # Remove source files and packages used for building to reduce image size
    && apt-get remove -y \
       build-essential \
       autoconf \
       git \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /ejabberd \

    # Setting the correct permissions on the directory
    && mkdir /run/ejabberd \
    && chown -R ejabberd:ejabberd /etc/ejabberd /var/lib/ejabberd /var/log/ejabberd /run/ejabberd \
    && chmod +x /usr/sbin/ejabberdctl \
    && chown -R ejabberd:ejabberd /usr/sbin/ejabberdctl

USER ejabberd
CMD ["ejabberdctl", "foreground"]
