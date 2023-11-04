# noreutils -- my own take on coreutils for personal use
Noreutils are just here for my personal use as a replacement for GNU coreutils. It's still incomplete, the main goal is to remove everything I don't need and to add new stuff to existing utilities (base64 can now encode and decode) and add new utilities/replacements for GNU utilities (rm is replaced with trash, which lets you make mistakes)

# all utilities
`base64` - encode/decode base64 data/files
`cat` - concatenate file(s)' data to stdout
`clear` - (INCOMPLETE) clear the terminal
`du` - (INCOMPLETE) show info about a file
`echo` - print input to the standard output
`mv` - move files/directories
`trash` - a safer alternative to `rm`, store files in ~/.trash, encrypt them optionally, recover them, and delete them when you want
`json` - work with JSON in a painless manner
`net` - send HTTP requests to web servers

# installation
To build the "bootstrap" binary, run:
```
nimble build -d:release
```
Do not forget `-d:release` as otherwise, all binaries will be built with debug symbols.
Then, run the `noreutils` binary that just got generated. All the coreutils will be compiled by it into the `bin/` directory.

Most coreutils have a `--help` command.
