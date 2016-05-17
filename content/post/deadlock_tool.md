+++
date = "2016-03-20T13:00:00+02:00"
tags = ["go", "golang", "deadlock", "debug", "tool"]
title = "Micropost on Go : Debug a deadlock"
url = "/debug-a-deadlock"
+++


Here is a trick that I learned from the awesome presentation (https://speakerdeck.com/mitchellh/advanced-testing-with-go) of Mitchell Hashimoto (https://twitter.com/mitchellh). When you are stuck in a deadlock situation that is tricky to resolve (for example when it needs special conditions to be triggered) and that you have not enough log to investigate, you can use a special move to understand.

You can simply kill the program by using a *SIGQUIT* instead of a *SIGTERM*. It will output the trace of every goroutine of your program.

There are simple ways to achieve it :

* If you launched the program, use ctrl+\ on linux
* Use htop and the kill option
* Use simply kill -s SIGQUIT [pid]

It saved my day. Thanks for the trick, Mitchell ! (and read the rest of the presentation, it is pretty cool).
