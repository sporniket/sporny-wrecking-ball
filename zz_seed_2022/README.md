> This is a work in progress.

# A game seed by Sporniket

## How to use

The intended workflow will be something along :

1. duplicate the folder
1. change things
1. ?
1. profit !

### Duplicate the folder

The folder contains : 

* **TO BE DONE**
* `_main.s` : the source file that will tie the whole thing. Normally, one will NOT need to change anything there.
* `0_heapmp.s` : the structure of the heap, that will define the required size.
* `app.s` : you start to write your new program there. Some parts MUST be kept so that `_main.s` can work out things.
* `Makefile` : the makefile to build the binary. Some parts MUST be kept so that it works. It is expected that a `dependencies.local.mk` will be generated do list the involved files as _sources_, _includes_ and _assets_. 
* `assets` : a folder to put all the data to embed into the binary or to accompany the binary.
* `includes` : a folder to put all the sources that will be included by your program.

### Change things

**TO BE DONE**

Not including the writing of the actual program, there are some edits that are needed to adapt the seed :

* Memory management (heap and stack) ; _define the structure of the heap in `0_heapmp.s`_ ; _stack size to be defined as a define in the makefile or a separate makefile include, and used inside `_main.s`_
* Select Hardware checks and requirements ; _FIXME defines in the makefile, or makefile include_ ; _FIXME add conditionnals in `_main.s` to enable/disable the call to the target hardware check_
* ...

### ?

* **TO BE DONE**
* Add your general macro on the top section _FIXME mark the insertion point in `_main.s`_
* Add your general libs (subroutines) and other things on the bottom section _FIXME mark the insertion point in `_main.s`_
* Script the building process to create the set of files needed to be distributed.

### Profit !

* Use `make` to build the files to distribute and make an archive
* Test the distribution archive to validate that it behaves as expected
* Distribute the archive.
* **ANYTHING ELSE ?** it's up to you