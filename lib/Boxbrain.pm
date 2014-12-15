use v6;

my constant DEBUG = 1;

module Terminal::Control {
    our %human-commands;
    our %human-controls;
    our %tput-controls;
    our %attributes;
    our %attribute-values;

    INIT {
        %human-commands = %(
            'clear'              => 'clear',
            'save-screen'        => 'smcup',
            'restore-screen'     => 'rmcup',
            'pos-cursor-save'    => 'sc',
            'pos-cursor-restore' => 'rc',
            'hide-cursor'        => 'civis',
            'show-cursor'        => 'cnorm', 
        );
        for %human-commands.kv -> $human,$command {
            %tput-controls<<$command>> = qq:x{ tput $command };
            %human-controls<<$human>> = %tput-controls<<$command>>;
        }

        %attributes = %(
            'columns'       => 'cols',
            'rows'          => 'lines',
        );

        %attribute-values<columns>  = %*ENV<COLUMNS> //= qq:x{ tput cols };
        %attribute-values<rows>     = %*ENV<ROWS>    //= qq:x{ tput lines };
    }

    our sub cursor_to( Int $x, Int $y ) {
        "\e[{$x};{$y}H"; # we are using the hardcoded ANSI because it's the
                         # least inelegant solution
    }

    our sub tput( Str $command ) {
        die "Not a supported (or perhaps even valid) tput command"
            unless %tput-controls<<$command>>;

        %tput-controls<<$command>>;
    }
}

constant T = ::Terminal::Control;

class Boxbrain::Cell {
    has $.x is rw;
    has $.y is rw;
    has $.char is rw;
    has %.attr is rw;
    has $!print-string;

    # not working as expected ...
    method set( :$x, :$y, :$char ) {
        $!x = $x ?? $x !! $!x;
        $!y = $y ?? $y !! $!y;
        $!char = $char ?? $char !! $char;
    }

    # TODO: throw specific exceptions if any of these vars are undef
    method cell-string {
        $!print-string //= "{T::cursor_to($!y,$!x)}{$!char}";
    }

    method print-cell {
        die self.perl.say unless $!x,$!y,$!char;
        $!print-string //= "{T::cursor_to($!y,$!x)}{$!char}";
        print $!print-string;
    }
}

# make columns a class so that we can do at_pos
class Boxbrain::Column {
    has @.cells is rw;
    has $.column;
    has $!max-row;

    method new( :$max-row, :$column ) {
        my @cells; for 0..$max-row { @cells[$_] = Boxbrain::Cell.new };
        self.bless( :$max-row, :$column, :@cells );
    }

    method at_pos( $y ) {
        @!cells[$y];
    }
    
    method assign_pos ( $y, Str $char ) {
        @!cells[$y].char = $char;
    }

}

class Boxbrain {
    has @!current-buffer;
    has @!current-grid;

    has @!buffers;
    has @!grids;

    has @.grid-indices;
    has $.max-column;
    has $.max-row;

    method new( *@args ) {
        self.bless(@args);
    }

    submethod BUILD {
        $!max-column = %T::attribute-values<columns>;
        $!max-row = %T::attribute-values<rows>; 
        @!grid-indices = (0..^$!max-column X 0..$!max-row).map({ [$^c, $^r] });

        for 0..^$!max-column -> $x {
            @!current-grid[ $x ] //= Boxbrain::Column.new( :$!max-row, column => $x );
            for @!current-grid[ $x ].cells.kv -> $i,$c { $c.x = $x; $c.y = $i; $c.char = ' '; };
        }

        for @!grid-indices -> [$x,$y] {
            @!current-buffer[$x + ($y * $!max-column)] := @!current-grid[ $x ][ $y ];
        }

        # we will support creating extra buffers
        push @!buffers, @!current-buffer;
        push @!grids, @!current-grid;
    }

    method blit( $store = False ) {
        say [~] @!current-buffer.map: { .char };
    }

    method at_pos( $column ) {
        @!current-grid[ $column ];
    }

    method postcircumfix:<( )> ($t) {
        die "Can only specify x, y, and char" if @$t > 3;
        my ($x,$y,$char) = @$t;
        given +@$t {
            when 3 { @!current-grid[ $x ][ $y ] = $char }
            when 2 { @!current-grid[ $x ][ $y ] }
            when 1 { @!current-grid[ $x ] }
        }
    }

# TODO: multiple buffers and grids
#    method clear-grid {
#        for @!current-grid[ $x ].cells -> $c { $c.set( :$x, :char(' ') ) };
#    }

    # 'clear' will also work through the FALLBACK
    method clear-screen {
        print %T::human-controls<clear>;
    }

    method initialize-screen {
        print %T::human-controls<save-screen>;
        self.hide-cursor;
        self.clear-screen;
    }

    method shutdown-screen {
        print %T::human-controls<restore-screen>;
        self.show-cursor;
    }

    multi method FALLBACK( Str $command-name ) {
        die "Do not know command $command-name" unless %T::human-controls{$command-name};
        print %T::human-controls{$command-name};
    }

}

my $b = Boxbrain.new;

#$b.blit;
##$b.blit("Z");
##$b.blit("!");
#
##$b(3,4).perl.say;
##$b(3,).perl.say;
#
#$b(6,30).char = '$';
#$b(7,30,'*');
#
#$b[6][31] = "%";
#
#$b.blit;
#
#sleep 2;

$b.initialize-screen;

my @hearts;
for $b.grid-indices -> [$x,$y] {
    do { $b[$x][$y] = '♥'; push @hearts, [$x,$y] } if $x+1 %% 2 or $y+1 %% 3;
}

for @hearts.pick( +@hearts ) -> [$x,$y] {
    $b[$x][$y].print-cell;
}

sleep 4;

$b.shutdown-screen;



