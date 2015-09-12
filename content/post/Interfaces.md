+++
date = "2015-09-10T19:00:43+01:00"
tags = ["go", "golang", "interface", "cost", "summary"]
title = "What is the cost of Go interfaces"
+++

### Summary 

We all know the benefits of using go interfaces in our projects. It's reliable, clean and allows differents projects to work together. But what is the cost of using them and let's be clear, this post doesn't aims to be against them. It's an awesome feature and sometimes it is better to sacrifice some performance to have cleaner softwares.

### What are the interfaces in memory ?

Like [this slide](https://docs.google.com/presentation/d/1lL7Wlh9GBtTSieqHGJ5AUd1XVYR48UPhEloVem-79mA/edit#slide=id.gc5ec805d9_0_480) explains, an interface is composed of two words (two information) : an envelope and a body. The first part describe the type of the underlying type and the second part is the data as itself : a pointer to the data if it's the case or a value.

In term of memory it adds 8 bytes around each value passed as an interface.

### What is the cpu cost to assert an interface to another type (interface or structure)

Let's write some simple simples actions :

```go

type testSTruct struct {
	id int8
}

func (t *testSTruct) GetId() int8 {
	return t.id
}

type testInterface interface {
	GetId() int8
}

func PerformAction(t *testSTruct) {
	t.id = 8
}

func PerformActionOnCastedInterfaceIf(t testInterface) {
	if struc, ok := t.(*testSTruct); ok {
		struc.id = 8
	}
}

func PerformActionOnCastedInterfaceNoIf(t testInterface) {
	t.(*testSTruct).id = 8
}

func PerformActionOnCastedInterfaceSwitch(t testInterface) {
	switch struc := t.(type) {
	case *testSTruct:
		struc.id = 8
	}
}
```

* **PerformAction** : first function, I set a value on a struct passed by pointer, this is the placebo
* **PerformActionOnCastedInterfaceIf** : First real test, I assert my interface as the original test but with test to ensure that it doesn't panic and I execute the same action as the placebo
* **PerformActionOnCastedInterfaceNoIf** : Second test, I assert **without** checking if the interface has the good underlying type : it will panic if it's not the case
* **PerformActionOnCastedInterfaceSwitch** : Last test, the test is done like the second test, but with a switch


And some simple benchmarks on them :

```go

func BenchmarkPerformActionOnStruct(b *testing.B) {
	b.ReportAllocs()
	t := testSTruct{2}
	for i := 0; i < b.N; i++ {
		PerformAction(&t)
	}
}

func BenchmarkPerformActionOnCastedInterfaceIf(b *testing.B) {
	b.ReportAllocs()
	t := testSTruct{2}
	for i := 0; i < b.N; i++ {
		PerformActionOnCastedInterfaceIf(&t)
	}
}

func BenchmarkPerformActionOnCastedInterfaceNoIf(b *testing.B) {
	b.ReportAllocs()
	t := testSTruct{2}
	for i := 0; i < b.N; i++ {
		PerformActionOnCastedInterfaceNoIf(&t)
	}
}

func BenchmarkPerformActionOnCastedInterfaceSwitch(b *testing.B) {
	b.ReportAllocs()
	t := testSTruct{2}
	for i := 0; i < b.N; i++ {
		PerformActionOnCastedInterfaceSwitch(&t)
	}
}
```

To run those tests on each go version we want, let's write a Dockerfile by version :

```
# Start from a Debian image with the latest version of Go installed
# and a workspace (GOPATH) configured at /go.
FROM golang:1.5.1	

ENV GOMAXPROCS 1

# Copy the local package files to the container's workspace.
ADD . /go/src/github.com/mrsinham/it

# Build the outyet command inside the container.
# (You may fetch or manage dependencies here,
# either manually or with a tool like "godep".)
ENTRYPOINT go version && cd /go/src/github.com/mrsinham/it && go test -bench=.
```

We save them as 1.5.1, 1.4.2, etc…

To run them, a simple bash loop :

```bash
#!/bin/bash
for goversion in 1.4.0 1.4.2 1.5.0 1.5.1; do sudo docker build -f $goversion -t interface_test:$go_version . && sudo docker run interface_test:$go_version ; done
```

And let's see the results of our tests :

```
go version go1.4 linux/amd64
PASS
BenchmarkPerformActionOnStruct	2000000000	         0.37 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceIf	100000000	        11.5 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceNoIf	100000000	        11.0 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceSwitch	100000000	        13.5 ns/op	       0 B/op	       0 allocs/op
```

```
go version go1.4.2 linux/amd64
PASS
BenchmarkPerformActionOnStruct	2000000000	         0.36 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceIf	100000000	        11.4 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceNoIf	100000000	        10.9 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceSwitch	100000000	        13.3 ns/op	       0 B/op	       0 allocs/op
```

```
go version go1.5 linux/amd64
PASS
BenchmarkPerformActionOnStruct               	2000000000	         0.35 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceIf    	2000000000	         1.95 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceNoIf  	2000000000	         1.84 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceSwitch	300000000	         4.58 ns/op	       0 B/op	       0 allocs/op
```

```
go version go1.5.1 linux/amd64
PASS
BenchmarkPerformActionOnStruct               	2000000000	         0.35 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceIf    	2000000000	         1.96 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceNoIf  	2000000000	         1.82 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceSwitch	300000000	         4.69 ns/op	       0 B/op	       0 allocs/op
```

What can we say about the results ? 

* In Go 1.4.* the interface assertion/conversion costs a lot (it's in *ns* so "a lot" is not catastrophic at all) but the difference is from 0.37 ns to 11.5 ns from BenchmarkPerformActionOnStruct to BenchmarkPerformActionOnCastedInterfaceIf. It's x31 the placebo time to add an interface conversion/assertion.
* In Go 1.5.* we are from 0.35 to 1.96 so x5.5 the placebo time
* With no assertion test, it is cheaper but not with a great difference
* Switch are expensives, with no surprises at all

## Summary :

* In Go 1.4, interfaces assertions we not as cheap as I thought but it was not very expensive. In Go 1.5, the cost  becomes very cheap but is still here, adding a tiny presence to the code.
* 0 allocs/op the benchmarks are saying. So, if interfaces scared you about the memory, just remember of the 8 bytes added in the interface enveloppe, that's all.



The interfaces cost 2 words.
https://docs.google.com/presentation/d/1lL7Wlh9GBtTSieqHGJ5AUd1XVYR48UPhEloVem-79mA/edit#slide=id.gc5ec805d9_0_518


Document sur le profile de https://github.com/bradfitz/talk-yapc-asia-2015/blob/master/talk.md

Interface pollution

https://medium.com/@rakyll/interface-pollution-in-go-7d58bccec275 (Borcu Dogan)


testing: warning: no tests to run
PASS
BenchmarkNormal-8                              	2000000000	         0.35 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceIf-8    	2000000000	         1.94 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceNoIf-8  	2000000000	         1.84 ns/op	       0 B/op	       0 allocs/op
BenchmarkPerformActionOnCastedInterfaceSwitch-8	300000000	         4.62 ns/op	       0 B/op	       0 allocs/op
ok  	github.com/mrsinham/it	10.534s
11:33 julien@Saneel ~/Programmation/Gola

