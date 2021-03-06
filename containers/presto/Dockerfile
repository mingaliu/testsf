#

FROM ubuntu:14.04

ENV PRESTO_VERSION=0.179
ENV PRESTO_HOME=/usr/local/presto
ENV BASE_URL=https://repo1.maven.org/maven2/com/facebook/presto

# install dev tools
RUN apt-get update
RUN apt-get install -y curl tar sudo rsync python wget

# java
RUN mkdir -p /usr/java/default && \
	 curl -Ls 'http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz' -H 'Cookie: oraclelicense=accept-securebackup-cookie' | \
     tar --strip-components=1 -xz -C /usr/java/default/

# ADD jdk-8u112-linux-x64.tar.gz /usr/java
# RUN sudo ln -s /usr/java/jdk1.8.0_112/ /usr/java/default

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin

WORKDIR /usr/local
RUN wget ${BASE_URL}/presto-server/${PRESTO_VERSION}/presto-server-${PRESTO_VERSION}.tar.gz \
	     ${BASE_URL}/presto-cli/${PRESTO_VERSION}/presto-cli-${PRESTO_VERSION}-executable.jar
RUN ln -s /usr/local/presto-server-${PRESTO_VERSION} $PRESTO_HOME

# Install Presto
RUN chmod +x presto-*executable.jar \
	&& tar zxvf presto-server-${PRESTO_VERSION}.tar.gz \
	&& ln -s presto-server-${PRESTO_VERSION} presto \
	&& mv *.jar presto/. \
	&& cd presto \
	&& ln -s presto-cli-${PRESTO_VERSION}-executable.jar presto \
	&& ln -s presto-verifier-${PRESTO_VERSION}-executable.jar verifier \
	&& ln -s presto-benchmark-driver-${PRESTO_VERSION}-executable.jar benchmark-driver \
	&& cd -

# Create data dir
#RUN mkdir -p $PRESTO_HOME/data
VOLUME ["$PRESTO_HOME/etc", "$PRESTO_HOME/data"]

#3. HDI integration layer
# Add Tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
	
ADD ./src /
RUN chmod +x /start.sh

WORKDIR /usr/local/presto

ENTRYPOINT ["/tini", "--"]
# Run your program under Tini
CMD ["/start.sh"]
