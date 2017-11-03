FROM mro-base:3.4.1

# Install basic apt packages
RUN apt-get update && apt-get -y --no-install-recommends install \
  file \
  git \
  libapparmor1 \
  libcurl4-openssl-dev \
  libedit2 \
  libssl-dev \
  lsb-release \
  psmisc \
  python-setuptools \
  sudo \
  wget \
  libxml2-dev \
  libcairo2-dev \
  libsqlite-dev \
  libmariadbd-dev \
  libmariadb-client-lgpl-dev \
  libpq-dev \
  libssh2-1-dev

# Install basic R pacakges
RUN R -e "install.packages(c('devtools', 'ggplot2'))"

# Install bioconductor
RUN R -e "source('https://bioconductor.org/biocLite.R')"