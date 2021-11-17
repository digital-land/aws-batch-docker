FROM debian:stable-slim

RUN echo 'export $(strings /proc/1/environ | grep AWS_CONTAINER_CREDENTIALS_RELATIVE_URI)' >> /root/.profile
RUN apt-get update
RUN apt-get -y install build-essential libsqlite3-dev zlib1g-dev make curl wget unzip git python3 python3-pip sudo time sqlite3 libsqlite3-mod-spatialite ca-certificates gnupg lsb-release
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get -y install docker-ce docker-ce-cli containerd.io
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install
RUN git clone https://github.com/mapbox/tippecanoe.git && cd tippecanoe && make -j && make install

ADD fetch_and_run.sh /usr/local/bin/fetch_and_run.sh
ADD eu-west-2-bundle.pem /usr/local/bin/eu-west-2-bundle.pem

ENTRYPOINT ["/usr/local/bin/fetch_and_run.sh"]
