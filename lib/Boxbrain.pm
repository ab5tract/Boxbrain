use v6;

my constant DEBUG = 1;

module Terminal::Print {
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
            %tput-controls{$command} = qq:x{ tput $command };
            %human-controls{$human} = %tput-controls{$command};
        }

        %attributes = %(
            'columns'       => 'cols',
            'rows'          => 'lines',
            'lines'         => 'lines',
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
            unless %tput-controls{$command};

        %tput-controls{$command};
    }
}


constant T = ::Terminal::Print;

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

    method Str {
        self.cell-string;
    }
}

# make columns a class so that we can do at_pos
class Boxbrain::Column {
    has @.cells is rw;
    has $.column;
    has $!max-rows;

    method new( :$max-rows, :$column ) {
        my @cells; for 0..$max-rows { @cells[$_] = Boxbrain::Cell.new };
        self.bless( :$max-rows, :$column, :@cells );
    }


    method at_pos( $y ) {
        @!cells[$y];
    }
    
    method assign_pos ( $y, Str $char ) {
        @!cells[$y].char = $char;
    }

}

class Boxbrain::Grid {
    has @.grid;
    has @.buffer;

    has $.max-columns;
    has $.max-rows;

    has @.grid-indices;
    has @.column-range;
    has @.row-range;

    method new( :$max-columns, :$max-rows ) {
        my @column-range = (0..^$max-columns).values;
        my @row-range = (0..$max-rows).values;
        my @grid-indices = (@column-range X @row-range).map({ [$^x, $^y] });

        my (@grid, @buffer);
        for @column-range -> $x {
            @grid[ $x ] //= Boxbrain::Column.new( :$max-rows, column => $x );
            for @grid[ $x ].cells.kv -> $y, $cell {
                $cell.x = $x;
                $cell.y = $y;
                $cell.char = ' ';  # TODO: self.clear-buffer / move this where it belongs
            }
        }

        for @grid-indices -> [$x,$y] {
            @buffer[$x + ($y * $max-columns)] := @grid[ $x ][ $y ];
        }

        self.bless( :$max-columns, :$max-rows, :@grid-indices,
                    :@column-range, :@row-range, :@grid, :@buffer );
    }

    method at_pos( $column ) {
        @!grid[ $column ];
    }

    method Str {
        my $grid-string;
        for 0..$!max-rows -> $y {
            $grid-string ~= [~] ~@!grid[$_][$y] for @!column-range;
        }
        return $grid-string;
    }
}


class Boxbrain {
    has $!current-buffer;
    has Boxbrain::Grid $!current-grid;

    has @!buffers;
    has Boxbrain::Grid @!grids;

    has @.grid-indices;
    has %!grid-map;

    has $.max-columns;
    has $.max-rows;

    method new {
        my $max-columns   = +%T::attribute-values<columns>;
        my $max-rows      = +%T::attribute-values<rows>;

        my $grid = Boxbrain::Grid.new( :$max-columns, :$max-rows );
        my @grid-indices = $grid.grid-indices;

        self!bind-buffer( $grid, my $buffer = [] );

        self.bless(
                    :$max-columns, :$max-rows, :@grid-indices,
                        current-grid    => $grid,
                        current-buffer  => $buffer
                  );
    }

    submethod BUILD( :$current-grid, :$current-buffer, :$!max-columns, :$!max-rows, :@!grid-indices ) {
        # TODO: bind grid-indices to @!grids[0].grid-indices?
        push @!buffers, $current-buffer;
        push @!grids, $current-grid;

        $!current-grid   := @!grids[0];
        $!current-buffer := @!buffers[0];
    }

    method !bind-buffer( $grid, $new-buffer is rw ) {
        for $grid.grid-indices -> [$x,$y] {
            $new-buffer[$x + ($y * $grid.max-rows)] := $grid[$x][$y];
        }
    }

    method add-grid( $name? ) {
        my $new-grid = Boxbrain::Grid.new( :$!max-columns, :$!max-rows );

        self!bind-buffer( $new-grid, my $new-buffer = [] );

        push @!grids, $new-grid;
        push @!buffers, $new-buffer;

        if $name {
            %!grid-map{$name} = +@!grids-1;
        }
    }

    method blit( $grid-identifier = 0 ) {
        self.clear-screen;
        print ~self.grid-object($grid-identifier);
    }

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

    # at_pos hands back a Boxbrain::Column
    #   $b[$x]
    # Because we have at_pos on the column object as well,
    # we get
    #   $b[$x][$y]
    #
    # TODO: implement $!current-grid switching
    method at_pos( $column ) {
        $!current-grid.grid[ $column ];
    }

    # at_key returns the Boxbrain::Grid.grid of whichever the key specifies
    #   $b<specific-grid>[$x][$y]
    method at_key( $grid-identifier ) {
        self.grid( $grid-identifier );
    }

    method postcircumfix:<( )> ($t) {
        die "Can only specify x, y, and char" if @$t > 3;
        my ($x,$y,$char) = @$t;
        given +@$t {
            when 3 { $!current-grid[ $x ][ $y ] = $char }
            when 2 { $!current-grid[ $x ][ $y ] }
            when 1 { $!current-grid[ $x ] }
        }
    }

    multi method FALLBACK( Str $command-name ) {
        die "Do not know command $command-name" unless %T::human-controls{$command-name};
        print %T::human-controls{$command-name};
    }

    # multi method sugar:
    #    @!grids and @!buffers can both be accessed by index or name (if it has
    #    one). The name is optionally supplied when calling .add-grid.
    #
    #    In the case of @!grids, we pass back the grid array directly from the
    #    Boxbrain::Grid object, actually notching both DWIM and DRY in one swoosh.
    multi method grid( Int $index ) {
        @!grids[$index].grid;
    }

    multi method grid( Str $name ) {
        die "No grid has been named $name" unless my $grid-index = %!grid-map{$name};
        @!grids[$grid-index].grid;
    }

    #   Sometimes you simply want the object back (for stringification, or
    #   introspection on things like column-range)
    multi method grid-object( Int $index ) {
        @!grids[$index];
    }

    multi method grid-object( Str $name ) {
        die "No grid has been named $name" unless my $grid-index = %!grid-map{$name};
        @!grids[$grid-index];
    }

    multi method buffer( Int $index ) {
        @!buffers[$index];
    }

    multi method buffer( Str $name ) {
        die "No buffer has been named $name" unless my $buffer-index = %!grid-map{$name};
        @!buffers[$buffer-index];
    }
}


use Term::ANSIColor;
my @colors = <red magenta yellow white>;

my $b = Boxbrain.new;

$b.initialize-screen;

$b.add-grid("5s");

my @hearts;
for $b.grid-indices -> [$x,$y] {
    next if $x ~~ 0;
    if $x %% 3 and $y+1 %% 3 {
        $b[$x][$y] = colored('♥', @colors.roll);
        push @hearts, [$x,$y];
        $b<5s>[$x][$y] = colored('5', @colors.roll);
        push @hearts, [$x,$y];
    }
}


for @hearts.pick( +@hearts ) -> [$x,$y] {
    $b[$x][$y].print-cell;
#    my $range = 0..0.010;
#    sleep 0.05 + $range.pick;   # longer hug
}

$b.blit("5s");
sleep 0.5;
$b.blit;
sleep 0.5;
$b.blit(1);
sleep 0.5;
$b.blit;
sleep 0.5;
$b.blit(1);
sleep 0.5;
$b.blit;
sleep 0.5;
$b.blit(1);
sleep 0.5;
$b.blit;
sleep 0.5;
$b.blit(1);
sleep 0.5;
$b.blit;
sleep 0.5;
$b.blit(1);
sleep 0.5;
$b.blit;
sleep 0.5;


#sleep 4;

$b.shutdown-screen;
