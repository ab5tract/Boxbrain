# Boxbrain

Pure Perl 6 command-line GUI library

## History

At first I thought I might try writing a NativeCall wrapper around ncurses. Then I realized that there is absolutely no reason to fight a C library which has mostly bolted on Unicode when I can do it in Pure Perl 6, with native Unicode goodness.

## Concept
_(This code is currently alpha, so a concept statement seems important. If anyone feels like seeing pieces of this come true sooner rather than later, patches are more than welcome.)_

`Boxbrain` hopes to be the first plug-and-play async command line display surface. Utilizing terminal-specific escape sequences carefully garnered from the `tput` command, the `Terminal::Print` family (currently implemented only here) will be brought in as a role. This should allow transparent support when shifting between xterm or tmux, for instance.

Hopeful syntax:

  `boxbrain --external-config monitors.json`

The config would provide an array of settings hashes: `{ base-url, key?, query, sync-closure?, sync-trigger, geometry }`. The `geometry` setting can be an ad-hoc `details` hash or provide a lookup key for the optional top-level `details` structure.

A failure to apportion your geometry correctly will be considered a user error, as Perl 6 has native rationals :)

## Usage

Right now it only provides a grid with some nice access semantics.

  my $screen = Boxbrain.new;
  $screen[9][23] = "%";    # prints the escape sequence to put '%' on line 9 column 23
  $screen[9][23];          # returns "%"
  
  $screen(9,23,"%");       # another way, designed for golfing. there should be a whole sub-module to support golfing (hello, `enum`)

(Note that these are subject to change as the library more fully develops).

But the idea is that in the long-term you will be able to specify views either programmatically or through a JSON structure. These views will support async updates from whatever sources one might desire, allowing for quick hacking together of different "command center"-style scripts.

But if you want to see a pretty display of hearts filling your terminal, just `perl6 Boxbrain.pm` and enjoy. (Even more fun if you set your font size really small ;) ).

## TODO

- Currently this code contains another module, `Terminal::Print`, that should really be spun off into it's own library. (I also need to convince tadzik that he should move `Term::ANSIColor` to the `Terminal` namespace, as `Term` could be a useful namespace for, erm, terms).
