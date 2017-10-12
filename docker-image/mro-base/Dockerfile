FROM ubuntu:16.04

# Install minimum requirements
RUN apt-get update -y
RUN apt-get install -y wget
RUN apt-get install -y build-essential

# Download MRO
RUN wget https://mran.microsoft.com/install/mro/3.4.1/microsoft-r-open-3.4.1.tar.gz

# Untar the file
RUN tar -xf microsoft-r-open-3.4.1.tar.gz

# Install
RUN ./microsoft-r-open/install.sh

# Clean up
RUN rm ./microsoft-r-open-3.4.1.tar.gz
RUN rm ./microsoft-r-open/install.sh

CMD ["R"]