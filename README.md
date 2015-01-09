# Boxbrain

Pure Perl 6 command-line GUI library

## History

At first I thought I might try writing a NativeCall wrapper around ncurses. Then I realized that there is absolutely no reason to fight a C library which has mostly bolted on Unicode when I can do it in Pure Perl 6, with native Unicode goodness.

## Usage

Right now it will take a bit of work, but the idea is that in the long-term you will be able to specify views either programmatically or through a JSON structure. These views will support async updates from whatever sources one might desire, allowing for quick hacking together of different "command center"-style scripts.

But if you want to see a pretty display of hearts filling your terminal, just `perl6 Boxbrain.pm` and enjoy. (Even more fun if you set your font size really small ;) ).

## TODO

- Currently this code contains another module, `Terminal::Print`, that should really be spun off into it's own library. (I also need to convince tadzik that he should move `Term::ANSIColor` to the `Terminal` namespace, as `Term` could be a useful namespace for, erm, terms).
