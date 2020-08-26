FROM rocker/rstudio:3.3.1
RUN export ADD=shiny && bash /etc/cont-init.d/add

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
#    libjq-dev \
    liblwgeom-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev
RUN R -e "source('https://bioconductor.org/biocLite.R')" \
&& install2.r --error \
    --deps TRUE \
    devtools \
    rjson \
    leaflet
RUN installGithub.r \
    --deps TRUE \
    misasa/MedusaRClient \
    misasa/chelyabinsk
RUN apt-get install -y --no-install-recommends \
    bzip2 \
    libreadline-dev \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/sstephenson/rbenv.git /opt/rbenv \
&& git clone https://github.com/sstephenson/ruby-build.git /opt/rbenv/plugins/ruby-build \
&& /opt/rbenv/plugins/ruby-build/install.sh
ENV PATH /opt/rbenv/bin:/opt/rbenv/shims:$PATH
ENV RBENV_ROOT /opt/rbenv
RUN echo 'export RBENV_ROOT="/opt/rbenv"' >> /etc/profile \
&& echo 'export PATH="${RBENV_ROOT}/bin:${PATH}"' >> /etc/profile \
&& echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh \
&& echo 'eval "$(rbenv init -)"' >> /etc/profile \
&& sh /etc/profile.d/rbenv.sh \
&& rbenv install 2.2.2 \
&& rbenv global 2.2.2 \
&& echo 'gem: --no-document' >> ~/.gemrc && cp ~/.gemrc /etc/gemrc && chmod uog+r /etc/gemrc \
&& gem update --system 2.7.8 \
&& gem source -a http://dream.misasa.okayama-u.ac.jp/rubygems/ \
&& gem install casteml