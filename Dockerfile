FROM debian:bullseye-slim

ARG MAKE_OPTIONS_JEMALLOC
ARG MAKE_OPTIONS_RUBY

ENV \
  GEM_HOME=/usr/local/bundle \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG=/usr/local/bundle \
  PATH=/usr/local/bundle/bin:$PATH \
  LANG=C.UTF-8

RUN set -eux && \
  \
  apt-get update -y && apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  g++ \
  gcc \
  libffi-dev \
  libgmp-dev \
  libssl-dev \
  libyaml-dev \
  make \
  zlib1g-dev \
  && \
  \
  savedAptMark="$(apt-mark showmanual)" && \
  \
  apt-get install -y --no-install-recommends \
  autoconf \
  bison \
  bzip2 \
  curl \
  dpkg-dev \
  libbz2-dev \
  libgdbm-compat-dev \
  libgdbm-dev \
  libglib2.0-dev \
  libncurses-dev \
  libreadline-dev \
  libxml2-dev \
  libxslt-dev \
  ruby \
  && \
  \
  ln -sf /usr/share/zoneinfo/Etc/GMT-9 /etc/localtime && \
  \
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
  PATH="$HOME/.cargo/bin:$PATH" && \
  \
  cd /tmp && \
  curl -L https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 | tar xjf - && \
  cd /tmp/jemalloc-5.3.0 && \
  ./configure --disable-doc --disable-static --disable-stats && make install $MAKE_OPTIONS_JEMALLOC && \
  cd / && rm -rf /tmp/jemalloc-5.3.0 && \
  ldconfig -v && \
  \
  mkdir -p /usr/local/etc && \
  echo 'gem: --no-document' > /usr/local/etc/gemrc && \
  mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME" && \
  \
  cd /tmp && \
  curl -L https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.1.tar.gz | tar xzf - && \
  cd /tmp/ruby-3.2.1 && \
  autoconf && \
  gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
  ./configure --build="$gnuArch" --with-jemalloc --disable-install-doc --enable-shared --enable-yjit --disable-install-static-library && \
  make install $MAKE_OPTIONS_RUBY && \
  cd / && rm -rf /tmp/ruby-3.2.1 && \
  ldconfig -v && \
  \
  rustup self uninstall -y && \
  \
  apt-mark auto '.*' > /dev/null && \
  apt-mark manual $savedAptMark && \
  find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd {} \; \
  | awk '/=>/ { print $(NF-1) }' | sort -u | grep -vE '^/usr/local/lib/' \
  | xargs -r dpkg-query --search | cut -d: -f1 | sort -u | xargs -r apt-mark manual && \
  \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/*
