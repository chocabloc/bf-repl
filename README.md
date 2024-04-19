# bf-repl
A [Brainfuck](https://en.m.wikipedia.org/wiki/Brainfuck) interpreter with a REPL, written in x86-64 NASM assembly for Linux.

###### Currently supports Brainfuck code and data upto 64 KiB each. Version using `malloc` coming soon.

## Usage

Clone the repository. To assemble from source, run `./bld`

To run a Brainfuck program, say `code.b`, run `./bf code.b`

To start the language shell, simply run `./bf`.
To exit, press <kbd>⏎ Enter</kbd> when prompted for a command.
> [!NOTE]
> Within a session, the position of the data pointer, as well as the data itself, is preserved across commands.

Click [here](http://brainfuck.org) for some sample Brainfuck programs and other information.
