+++
date = "2015-08-29T19:57:43+01:00"
tags = ["go", "golang", "deploy", "debian", "dependancies"]
title = "Golang project : easy deployment & fixed dependencies"
+++

## Perimeter

If you have a Golang project and you want to deploy them easily with all the external dependencies fixed, this post is for you ;)

#### 1.Fixing dependencies

In a project life, fixing the dependencies is very important. This is why all the langages have their tools. Pip, Composer, Npm, etc… well, all those tools offers a possibility to say that your app needs the 2.0 of the awesome-library and to ship/compile them automatically.

To fix dependencies in Go, there are many projects but I think the most used is [Godep](https://github.com/tools/godep) which will save all your dependencies in a **Godeps/_workspace** directory.

Inside of the Godeps directory, you will find a json with all the commit id of your files and all saved dependencies in the **Godeps/_workspace/src** dir.

When you execute **go build** it will take the dependencies of your **$GOPATH** env variable **BUT** if you use:

```bash
godep go build
```

It will use the dependencies stored in the Godeps tree. 

Example :

```
$GOPATH/src/
        \_ my/app/
                    \_Godeps/_workspace/src/my/dependency <- used with "godep go build"
        \_ my/dependency <- used with "go build"
```

The bonus part is that _workspace contains a **/pkg/** dir that makes a buffer for already compiled package and that this directory is automatically ignored by a .gitignore file created in the _workspace dir.

#### 2.Creating deployable application

Don't reinvent the wheel for the moment. We just need to create debian packages.

For this, we will use [Goxc](https://github.com/laher/goxc), a simple tool that can do many things as :

* create debian package
* run **go test**
* run **go vet**
* ...

Some steps :


```bash
go get -v -u github.com/laher/goxc
```

And we are almost done. Let's create a configuration file for goxc, which is named .goxc.json.

```
cat .goxc.json
```

```json
{
    "AppName": "MyApp",
    "BuildConstraints": "linux,amd64",    
    "ResourcesExclude": "*.go",
    "PackageVersion": "0.0.1",
    "TaskSettings": {
        "debs": {
            "bin-dir": "/home/path/to/deploy",
            "metadata": {
                "description": "My awesome app for go",
                "maintainer": "Julien Lefevre (https://github.com/mrsinham)"
            },
            "metadata-deb": {
                "Depends": "golang",
            },
            "other-mapped-files": {
                "/": "deb-contents/"
            }
        },
    },
    "ConfigVersion": "0.9",
    "BuildSettings": {
        "LdFlags": "-s",
        "LdFlagsXVars": {
            "TimeNow": "main.BUILD_DATE",
            "Version": "main.VERSION"
        }
    },
    "Env": [
        "GOPATH={{.Env.PWD}}{{.PS}}Godeps{{.PS}}_workspace{{.PLS}}{{.Env.GOPATH}}"
    ]
}
```

This will create a MyApp.deb after playing many configurable things. 

```
$ goxc
[goxc:go-vet] 2015/08/30 16:36:37 Task go-vet succeeded
ok      github.com/my/app    0.009s
[goxc:go-test] 2015/08/30 16:36:39 Task go-test succeeded
[goxc:go-install] 2015/08/30 16:36:39 Task go-install succeeded
[goxc:xc] 2015/08/30 16:36:39 Parallelizing xc for 1 platforms, using max 7 of 8 processors
# github.com/my/app
link: warning: option -X main.BUILD_DATE 2015-08-30T16:36:39+02:00 may not work in future releases; use -X main.BUILD_DATE=2015-08-30T16:36:39+02:00
link: warning: option -X main.VERSION 0.0.2 may not work in future releases; use -X main.VERSION=0.0.2
[goxc:xc] 2015/08/30 16:36:40 Task xc succeeded
[goxc:codesign] 2015/08/30 16:36:40 Task codesign succeeded
[goxc:copy-resources] 2015/08/30 16:36:40 IncludeGlobs: [INSTALL* README* LICENSE*]
[goxc:copy-resources] 2015/08/30 16:36:40 ExcludeGlobs: [*.go]
[goxc:copy-resources] 2015/08/30 16:36:40 Resources to include: []
[goxc:copy-resources] 2015/08/30 16:36:40 resources: []
[goxc:copy-resources] 2015/08/30 16:36:40 Task copy-resources succeeded
[goxc:archive-zip] 2015/08/30 16:36:40 Task archive-zip succeeded
[goxc:archive-tar-gz] 2015/08/30 16:36:40 Parallelizing archive-tar-gz for 1 platforms, using max 7 of 8 processors
[goxc:archive-tar-gz] 2015/08/30 16:36:40 IncludeGlobs: [INSTALL* README* LICENSE*]
[goxc:archive-tar-gz] 2015/08/30 16:36:40 ExcludeGlobs: [*.go]
[goxc:archive-tar-gz] 2015/08/30 16:36:40 Resources to include: []
[goxc:archive-tar-gz] 2015/08/30 16:36:42 Artifact(s) archived to $GOPATH/bin/MyApp-xc/0.0.2/MyApp_0.0.2_linux_amd64.tar.gz
[goxc:archive-tar-gz] 2015/08/30 16:36:42 Task archive-tar-gz succeeded
[goxc:deb] 2015/08/30 16:36:42 WARNING - no debian 'control' file found. Use `debber` to generate proper debian metadata
[goxc:deb] 2015/08/30 16:36:43 Wrote deb to $GOPATH/bin/MyApp-xc/0.0.2/MyApp_0.0.2_amd64.deb
[goxc:deb] 2015/08/30 16:36:43 Task deb succeeded
[goxc:deb-dev] 2015/08/30 16:36:43 WARNING - no debian 'control' file found. Use `debber` to generate proper debian metadata
[goxc:deb-dev] 2015/08/30 16:36:43 Task deb-dev succeeded
[goxc:rmbin] 2015/08/30 16:36:43 Task rmbin succeeded
[goxc:downloads-page] 2015/08/30 16:36:43 Task downloads-page succeeded
```

Et voilà ! You have a .deb ready for deployment in the $GOPATH/bin/MyApp-xc/0.0.1/ path. Because of the following configuration :

```json
"Env": [
        "GOPATH={{.Env.PWD}}{{.PS}}Godeps{{.PS}}_workspace{{.PLS}}{{.Env.GOPATH}}"
]
```

The goxc utility compiles with the same rules as Godeps and the generated .deb used the commited dependencies instead of the the developper GOPATH.
Well, after it's up to you ;)