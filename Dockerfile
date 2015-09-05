FROM ubuntu:15.04

RUN apt-get update && apt-get upgrade
RUN apt-get -y install git golang mercurial

RUN mkdir -p /go/src
ENV GOPATH /go/
RUN go get -v -u github.com/spf13/hugo

ENV PATH $PATH:/go/bin

RUN hugo new site /blog

RUN git clone https://github.com/mrsinham/blog.git /source

RUN cd /blog/ && rm -rf content/ && git init && git remote add -f origin https://github.com/mrsinham/blog.git && git config core.sparseCheckout true && echo "content/" >> .git/info/sparse-checkout && git pull origin master
RUN cp /source/config.toml /blog
RUN git clone https://github.com/dplesca/purehugo.git /blog/themes/purehugo


EXPOSE 1313

RUN echo 'hugo server -t purehugo -b="http://www.mrsinham.net" -s /blog -p 80 --bind=0.0.0.0 --watch --disableLiveReload &' >> /start.sh && \
echo 'cd /blog/content/' >> /start.sh && \ 
echo 'while true; do git pull origin master && sleep 60 ; done' >> /start.sh

RUN chmod +x /start.sh

#ENTRYPOINT hugo server -t purehugo -b="http://www.mrsinham.net" -s /blog -p 1414 --bind=0.0.0.0 
ENTRYPOINT /start.sh
