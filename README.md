# bf-repl
A [Brainfuck](https://en.m.wikipedia.org/wiki/Brainfuck) interpreter+REPL for x86_64 Linux, written in assembly.

# Specifics
* Supports program size upto 64 KiB and has 65536 cells.
* Doesn't require any third-party libraries (not even a `libc`).
* The minimal version (`bf-min`) is just 341 bytes!
* Can be used interactively or by loading the code from a file.

## Build Instructions

Make sure `nasm` and `binutils` are installed. Clone the repository and run `./bld`.

Alternatively, get the latest binary release from [Releases](huh)

## Usage

Run `./bf` for the REPL or `./bf <filename>` to run code from a file.
To exit the REPL, simply give it an empty command.
> [!NOTE]
> Within a session, the position of the data pointer, as well as the data itself, is preserved across commands.

## Extras

Click [here](http://brainfuck.org) for some sample Brainfuck programs and other information.
