+++
date = "2015-09-13T18:41:00+02:00"
tags = ["go", "golang", "interface", "cost", "summary"]
title = "What is the cost of go interfaces"
url = "/the-cost-of-golang-interfaces"
+++

## Summary 

We all know the benefits of using go interfaces in our projects. It's reliable, clean and allows differents projects to work together. But what is the cost of using them and let's be clear, this post doesn't aims to be against them. 
It's an awesome feature and sometimes it is better to sacrifice some performance to have cleaner softwares but I wanted to know more about them.

## What is the memory cost of interfaces ?

Like [this slide from Brad Fitzpatrick](https://docs.google.com/presentation/d/1lL7Wlh9GBtTSieqHGJ5AUd1XVYR48UPhEloVem-79mA/edit#slide=id.gc5ec805d9_0_480) explains, an interface is composed of two words (two information) : an envelope and a body. The first part describe the type of the underlying type and the second part is the data as itself : a pointer to the data if it's the case or a value.

![Slide from Brad Fitzpatric](http://i.imgur.com/b4qykAn.png)

If we read in this (old) page (http://www.airs.com/blog/archives/277) the last comment of **Ian Lance Taylor** (the author), written the 22 august 2015, it says :

```
The implementation description is no longer quite accurate. Today gccgo represents an interface value using a two word struct. The second word is a pointer to the value (if the value is a pointer type, the second word is the value itself). For an empty interface, the first word is a pointer to the type descriptor. For a non-empty interface, the first word is a pointer to a table of functions, but now the first pointer in the table of functions points to the type descriptor.
```

In term of memory it adds 8 bytes around each value passed as an interface, the value is represented by a pointer.

Let's write some tests to unterstand the memory comsuption.

First, let's write a placebo.

```go
package main 

const (
	nbStructToAdd = 1000000
)

type testStruct struct {
	id int8
}

func main() {

	var f *os.File
	var err error
	PerformAddingStructureToSlice()
	f, err = os.Create("/tmp/profiling_struct")
	if err != nil {
		panic(err)
	}
	pprof.WriteHeapProfile(f)
	f.Close()
}

func PerformAddingStructureToSlice() {
	var s []testStruct = make([]testStruct, 0, nbStructToAdd)
	for i := 0; i < nbStructToAdd; i++ {
		s = append(s, testStruct{2})
	}
}
```
And we obtain the memory analysis by using pprof.

```
go build && ./struct &&  go tool pprof struct /tmp/profiling_struct 
Entering interactive mode (type "help" for commands)
(pprof) top --cum
1664.86kB of 1664.86kB total (  100%)
      flat  flat%   sum%        cum   cum%
 1152.67kB 69.24% 69.24%  1152.67kB 69.24%  main.PerformAddingStructureToSlice
         0     0% 69.24%  1152.67kB 69.24%  main.main
         0     0% 69.24%  1152.67kB 69.24%  runtime.goexit
         0     0% 69.24%  1152.67kB 69.24%  runtime.main
  512.19kB 30.76%   100%   512.19kB 30.76%  runtime.malg
         0     0%   100%   512.19kB 30.76%  runtime.mcommoninit
         0     0%   100%   512.19kB 30.76%  runtime.mpreinit
         0     0%   100%   512.19kB 30.76%  runtime.rt0_go
         0     0%   100%   512.19kB 30.76%  runtime.schedinit
(pprof) list main.PerformAddingStructureToSlice
Total: 1.63MB
ROUTINE ======================== main.PerformAddingStructureToSlice in /home/julien/Programmation/Golang/src/github.com/mrsinham/it/memorysize/struct/main.go
    1.13MB     1.13MB (flat, cum) 69.24% of Total
         .          .     33:	pprof.WriteHeapProfile(f)
         .          .     34:	f.Close()
         .          .     35:}
         .          .     36:
         .          .     37:func PerformAddingStructureToSlice() {
    1.13MB     1.13MB     38:	var s []testStruct = make([]testStruct, 0, nbStructToAdd)
         .          .     39:	for i := 0; i < nbStructToAdd; i++ {
         .          .     40:		s = append(s, testStruct{2})
         .          .     41:	}
         .          .     42:}
(pprof) 
```

Ok, everything is ok. I'm not an expert on low level langagues but if I read this correctly (please correct me if I'm wrong :)) :

```
(8 bit+cost of struct) * 1000000 = not far from  1152.67kB
```

Let's write the same test with the interface now :

```go
package main

const (
	nbStructToAdd = 1000000
)

type testStruct struct {
	id int8
}

func (t testStruct) GetId() int8 {
	return t.id
}

type testInterface interface {
	GetId() int8
}

func main() {

	var f *os.File
	var err error
	PerformAddingInterfaceToSlice()
	f, err = os.Create("/tmp/profiling_interface")
	if err != nil {
		panic(err)
	}
	pprof.WriteHeapProfile(f)
	f.Close()
}

func PerformAddingInterfaceToSlice() {
	var s []testInterface = make([]testInterface, 0, nbStructToAdd)
	for i := 0; i < nbStructToAdd; i++ {
		s = append(s, testStruct{2})
	}
}
```

And we run a similar benchmark.

```
go build && ./interface &&  go tool pprof interface /tmp/profiling_interface 
Entering interactive mode (type "help" for commands)
(pprof) top --cum
16656.20kB of 16656.20kB total (  100%)
      flat  flat%   sum%        cum   cum%
16144.01kB 96.92% 96.92% 16144.01kB 96.92%  main.PerformAddingInterfaceToSlice
         0     0% 96.92% 16144.01kB 96.92%  main.main
         0     0% 96.92% 16144.01kB 96.92%  runtime.goexit
         0     0% 96.92% 16144.01kB 96.92%  runtime.main
  512.19kB  3.08%   100%   512.19kB  3.08%  runtime.malg
         0     0%   100%   512.19kB  3.08%  runtime.mcommoninit
         0     0%   100%   512.19kB  3.08%  runtime.mpreinit
         0     0%   100%   512.19kB  3.08%  runtime.rt0_go
         0     0%   100%   512.19kB  3.08%  runtime.schedinit
(pprof) list main.PerformAddingInterfaceToSlice
Total: 16.27MB
ROUTINE ======================== main.PerformAddingInterfaceToSlice in /home/julien/Programmation/Golang/src/github.com/mrsinham/it/memorysize/interface/main.go
   15.77MB    15.77MB (flat, cum) 96.92% of Total
         .          .     33:	pprof.WriteHeapProfile(f)
         .          .     34:	f.Close()
         .          .     35:}
         .          .     36:
         .          .     37:func PerformAddingInterfaceToSlice() {
   15.27MB    15.27MB     38:	var s []testInterface = make([]testInterface, 0, nbStructToAdd)
         .          .     39:	for i := 0; i < nbStructToAdd; i++ {
  512.01kB   512.01kB     40:		s = append(s, testStruct{2})
         .          .     41:	}
         .          .     42:}
(pprof) 
```

**Wow**. If I try to understand :

```
(8 bytes for type + 8 bytes for data) * 1 000 000 = not far from 16mB
```

### What can we say about the results ? 

* The interfaces are not very cheap structures or types, when you are creating one it has more cost than struct or other types.
* Using big slices/array of interfaces is probably not a good idea if you search to be memory efficient

### Summary

Interfaces are a great tool but because they can contain different types of data they must hold metadata informations that can be expensive if you are using them a lot. If you use them correctly, it won't be a problem (you often use them in function parameters).

## What is the cpu cost to assert an interface to another type (interface or structure)

Let's write some simple simples actions :

```go

type testStruct struct {
	id int8
}

func (t *testStruct) GetId() int8 {
	return t.id
}

type testInterface interface {
	GetId() int8
}

func PerformAction(t *testStruct) {
	t.id = 8
}

func PerformActionOnCastedInterfaceIf(t testInterface) {
	if struc, ok := t.(*testStruct); ok {
		struc.id = 8
	}
}

func PerformActionOnCastedInterfaceNoIf(t testInterface) {
	t.(*testStruct).id = 8
}

func PerformActionOnCastedInterfaceSwitch(t testInterface) {
	switch struc := t.(type) {
	case *testStruct:
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
	t := testStruct{2}
	for i := 0; i < b.N; i++ {
		PerformAction(&t)
	}
}

func BenchmarkPerformActionOnCastedInterfaceIf(b *testing.B) {
	b.ReportAllocs()
	t := testStruct{2}
	for i := 0; i < b.N; i++ {
		PerformActionOnCastedInterfaceIf(&t)
	}
}

func BenchmarkPerformActionOnCastedInterfaceNoIf(b *testing.B) {
	b.ReportAllocs()
	t := testStruct{2}
	for i := 0; i < b.N; i++ {
		PerformActionOnCastedInterfaceNoIf(&t)
	}
}

func BenchmarkPerformActionOnCastedInterfaceSwitch(b *testing.B) {
	b.ReportAllocs()
	t := testStruct{2}
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

### Summary :

* In Go 1.4, interfaces assertions we not as cheap as I thought but it was not very expensive. In Go 1.5, the cost  becomes very cheap but is still here, adding a tiny presence to the code.
* 0 allocs/op the benchmarks are saying. So, if interfaces scared you about the memory, just remember of the 8 bytes added in the interface enveloppe, that's all.


I don't remember where I read this but if you want to be ok, use this rule :

* If you can use constant, use it
* If you can't use constant, use variable
* If you can't use variable, use custom interface
* If you can't use custom interface, use interface{}

I will add this :

Go interfaces are great. There's a lot of articles that are proving the power that they provides to the go language. But just be aware that **they are not free**. But don't be paranoid :)


#### Note

* All this benchmarks are available at this address : [https://github.com/mrsinham/it](https://github.com/mrsinham/it)
* I could be wrong on some assumptions in this article : please let me know if you see them ;)
* My english … is far from perfect ;)