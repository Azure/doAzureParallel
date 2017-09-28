yum erase microsoft-r-open-mro-3.3* --assumeyes

if [ ! -d "microsoft-r-open" ]; then
    # Download R
    wget https://mran.microsoft.com/install/mro/3.4.0/microsoft-r-open-3.4.0.tar.gz

    # Untar the file
    tar -xf microsoft-r-open-3.4.0.tar.gz

    # Install
    ./microsoft-r-open/install.sh
fi 

# Update PATH on the node permanently
echo "export PATH=/usr/lib64/microsoft-r/3.4/lib64/R/bin:$PATH" >> /etc/environment

# Install bioconductor
Rscript -e 'source("https://bioconductor.org/biocLite.R")'
