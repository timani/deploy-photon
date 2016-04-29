FROM ubuntu:14.04

WORKDIR /tmp

RUN apt-get update

RUN apt-get install -yq build-essential \
  ruby ruby-dev \
  libxml2-dev \
  libsqlite3-dev \
  libxslt1-dev \
  libpq-dev \
  libmysqlclient-dev \
  wget \
  gcc \
  gcc-multilib \
  uuid \
  uuid-dev \
  perl \
  libssl-dev \
  perl-doc \
  liburi-perl \
  libxml-libxml-perl \
  libcrypt-ssleay-perl \
  zlib1g-dev && \
apt-get clean

RUN gem install bosh_cli --no-ri --no-rdoc
RUN gem install cf-uaac

RUN wget $(wget -q -O- https://github.com/vmware/photon-controller/wiki/download | grep "linux cli tools" | egrep -o http.*\" | tr -d "\"") -O /sbin/photon
RUN chmod 755 /sbin/photon

ADD VMware-vSphere-CLI-6.0.0-3561779.x86_64_MG.tar.gz /tmp/
RUN yes | /tmp/vmware-vsphere-cli-distrib/vmware-install.pl -d && \
    rm -rf /tmp/vmware-vsphere-cli-distrib

# Install VMware OVFTool http://vmware.com/go/ovftool
ADD VMware-ovftool-4.1.0-2459827-lin.x86_64.bundle /tmp/
RUN yes | /bin/bash /tmp/VMware-ovftool-4.1.0-2459827-lin.x86_64.bundle --required --console && \
    rm -f /tmp/VMware-ovftool-4.1.0-2459827-lin.x86_64.bundle

CMD ["/bin/bash"]
