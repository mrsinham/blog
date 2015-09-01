+++
date = "2015-09-01T12:30:00+01:00"
tags = ["go", "golang", "blog", "hugo", "docker"]
title = "Create a blog in 2 min with Hugo and Docker"
url = "/create-a-blog-in-2-min"
+++

## Perimeter

This post aims to create a blog engine with no database, no pain at all in 2 min. Well, perhaps not 2 min exactly but a very short amount of time. This use two technologies that I love, [Hugo](http://hugo.spf13.com) and [Docker](http://www.docker.com), both written in go. Let's be clear : it's to build the same blog engine as this one.

### Hugo :

Hugo is a very simple (but powerful) blog engine that converts Markdown files (recently reStructuredText files too) into html files served with by the http go stack.

### Docker :

Docker is a "virtualization platform" that allows you to create isoled "containers" that are running typically one task with all the needed dependencies. I'll let you read all the docs about this subject : they are plenty on the web.

### Git :

Well it needs git. But you need git too in your life ;)


## The structure of the project

Let's create a directory with all the files we need. Let's say it's **blog/**.

#### Hugo prerequisites :

* config.toml

Like every engine, Hugo needs a little bit of configuration. You can set many parameters, like the Hugo documentation says but here's mine, no secrets at all :

```toml
baseurl = "http://www.mrsinham.net/"
title = "MrSinham"
author = "Julien Lefèvre"
copyright = "Copyright (c) 2014, Julien Lefèvre; all rights reserved."
socialsharing = true
disqusShortname = "mrsinham"
[params]
    sidebartitle = "Mrsinham's Blog"
    sidebartagline = "IT thoughts"
[[menu.social]]
    pre = "<i class='fa fa-twitter'></i>"
    url = "http://www.twitter.com/mrsinham"
    identifier = "mrsinham"
```

Not a very big deal, isn't ? So we have now :

```
blog/config.toml
```

* One first article

Let's create the directory for the posts :

```
mkdir -p blog/content/post/
```

And the first post.

```
touch blog/content/post/my_awesome_post.md
```

Let's edit the content of this one :

```
+++
date = "2013-08-29T19:57:43+01:00"
tags = ["first"]
title = "Test post"
+++


### Test post

I just want to know if this works.
```

Ok now we have the Hugo config file and one post, we can now start the things.


Now that we have :

```
blog/config.toml
blog/content/post/my_awesome_post.md
```

We add this to an accessible Git repository (git add, git commit, git push). ! Don't add /blog, it's the root of the repository !


### Creating a Docker image for the blog

Now we must write a Dockerfile that will describe all the things we want in this container. It's the description of all things that 

Let's write a **Dockerfile** (fills the sections with your infos) :

```docker
FROM ubuntu:15.04

RUN apt-get update && apt-get upgrade
RUN apt-get -y install git golang mercurial

RUN mkdir -p /go/src
ENV GOPATH /go/
RUN go get -v -u github.com/spf13/hugo

ENV PATH $PATH:/go/bin

RUN hugo new site /blog

RUN cd /blog/ && rm -rf content/ && git init && git remote add -f origin https://github.com/my/blog.git && git config core.sparseCheckout true && echo "content/" >> .git/info/sparse-checkout && git pull origin master
RUN cp /source/config.toml /blog
RUN git clone https://github.com/dplesca/purehugo.git /blog/themes/purehugo

EXPOSE 80

RUN echo 'hugo server -t purehugo -b="http://www.fillthehost.com" -s /blog -p 80 --bind=0.0.0.0 --watch --disableLiveReload &' >> /start.sh && \
echo 'cd /blog/content/' >> /start.sh && \ 
echo 'while true; do git pull origin master && sleep 60 ; done' >> /start.sh

RUN chmod +x /start.sh

ENTRYPOINT /start.sh
```

And build it nicely :

```
docker build -t blog:dockerfile .
Sending build context to Docker daemon 4.608 kB
Sending build context to Docker daemon 
Step 0 : FROM ubuntu:15.04
 ---> 013f3d01d247
Step 1 : RUN apt-get update && apt-get upgrade
 ---> Using cache
 ---> 52052314932e
Step 2 : RUN apt-get -y install git golang mercurial
 ---> Using cache
 ---> b5b7d5ed16b4
Step 3 : RUN mkdir -p /go/src
 ---> Using cache
 ---> b8bb7fc9e73c
Step 4 : ENV GOPATH /go/
 ---> Using cache
 ---> b2eb013ada8a
Step 5 : RUN go get -v -u github.com/spf13/hugo
 ---> Using cache
 ---> d7e371cfe37d
Step 6 : ENV PATH $PATH:/go/bin
 ---> Using cache
 ---> 5ef2a841a9cf
Step 7 : RUN hugo new site /blog
 ---> Using cache
 ---> 86af998c54db
Step 9 : RUN cd /blog/ && rm -rf content/ && git init && git remote add -f origin [https://github.com/my/blog.git] && git config core.sparseCheckout true && echo "content/" >> .git/info/sparse-checkout && git pull origin master
 ---> Using cache
 ---> d232b0b426f6
Step 10 : RUN cp /source/config.toml /blog
 ---> Using cache
 ---> 04ff9f6cd7c2
Step 11 : RUN git clone https://github.com/dplesca/purehugo.git /blog/themes/purehugo
 ---> Using cache
 ---> 20a1d25e6136
Step 12 : EXPOSE 1414
 ---> Running in ac51135df480
 ---> 4add8a3493f5
Removing intermediate container ac51135df480
Step 13 : RUN echo 'hugo server -t purehugo -b="http://www.[fillthehost].com" -s /blog -p 80 --bind=0.0.0.0 &' >> /start.sh && echo 'cd /blog/content/' >> /start.sh && echo 'while true; do git pull origin master && sleep 60 ; done' >> /start.sh
 ---> Running in 42d8db52a3e7
 ---> cb41623a42f3
Removing intermediate container 42d8db52a3e7
Step 14 : RUN chmod +x /start.sh
 ---> Running in ea0239ee3a12
 ---> 40d75fde9c65
Removing intermediate container ea0239ee3a12
Step 15 : ENTRYPOINT /start.sh
 ---> Running in 81f9c7b032e1
 ---> 4a2f338105f7
Removing intermediate container 81f9c7b032e1
Successfully built 4a2f338105f7
```

Now that we have built the image, we can run it simply :

```
docker run -d -p 80:80 blog:dockerfile
```

Let's check now on http://127.0.0.1/ and we have our post displayed. More important is that when you add new posts to your blog repository, it will automatically be added to your website : in your dockerfile, every 60s the containers pulls modifications from the repo (and Hugo watch the changes !).

Note : the purehugo theme can be changed. Visit the Hugo site to find a template that suits you !