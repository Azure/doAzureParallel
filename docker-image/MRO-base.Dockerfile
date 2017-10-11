FROM debian:stretch

RUN wget https://mran.microsoft.com/install/mro/3.4.0/microsoft-r-open-3.4.1.tar.gz

# Untar the file
RUN tar -xf microsoft-r-open-3.4.1.tar.gz

# Install
RUN ./microsoft-r-open/install.sh

CMD["R"]