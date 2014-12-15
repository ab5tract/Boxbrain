use v6;

module Boxbrain::View::Termbox;

use NativeCall;

constant TERMBOX = 'libtermbox.1.0.0';

class TB_Cell is repr('CStruct') {
    has int32 $.ch;
    has int16 $.fg;
    has int16 $.bg;
}

constant TB_DEFAULT = 0x00; 
constant TB_BLACK   = 0x01;
constant TB_RED     = 0x02;
constant TB_GREEN   = 0x03;
constant TB_YELLOW  = 0x04;
constant TB_BLUE    = 0x05;
constant TB_MAGENTA = 0x06;
constant TB_CYAN    = 0x07;
constant TB_WHITE   = 0x08;

constant TB_BOLD       = 0x0100; 
constant TB_UNDERLINE  = 0x0200;
constant TB_REVERSE    = 0x0400;

sub tb_init 
    is native(TERMBOX)
    is export { ... };

sub tb_shutdown 
    is native(TERMBOX)
    is export { ... };

sub tb_width 
    is native(TERMBOX)
    is export { ... };

sub tb_height 
    is native(TERMBOX)
    is export { ... };

sub tb_clear 
    is native(TERMBOX)
    is export { ... };

sub tb_set_clear_attributes 
    is native(TERMBOX)
    is export { ... };

sub tb_present 
    is native(TERMBOX)
    is export { ... };

sub tb_set_cursor 
    is native(TERMBOX)
    is export { ... };

sub tb_change_cell( int $x, int $y, TB_Cell $cell )
    is native(TERMBOX)
    is export { ... };

sub tb_blit 
    is native(TERMBOX)
    is export { ... };

sub tb_cell_buffer 
    is native(TERMBOX)
    is export { ... };

our constant TB_INPUT_CURRENT = 0; 
our constant TB_INPUT_ESC     = 1;
our constant TB_INPUT_ALT     = 2;

sub tb_select_input_mode 
    is native(TERMBOX)
    is export { ... };

our constant TB_OUTPUT_CURRENT   = 0; 
our constant TB_OUTPUT_NORMAL    = 1;
our constant TB_OUTPUT_256       = 2;
our constant TB_OUTPUT_216       = 3;
our constant TB_OUTPUT_GRAYSCALE = 4;

sub tb_select_output_mode( int $output_mode )
    is native(TERMBOX)
    is export { ... };

sub tb_peek_event 
    is native(TERMBOX)
    is export { ... };

sub tb_poll_event 
    is native(TERMBOX)
    is export { ... };

sub tb_utf8_unicode_to_char( tb_uint, Str $char is rw )
    returns int
    is native(TERMBOX)
    is export { ... };

sub tb_utf8_char_to_unicode( tb_uint, Str $char is rw )
    returns int 
    is native(TERMBOX)
    is export { ... };

tb_init;
tb_select_output_mode(TB_OUTPUT_256);

class tb_char is OpaquePointer;
class tb_uint is OpaquePointer;

my $s = "B";
my $b = "V";

#$b  is encoded('ISO-8859-1');

#my $i = tb_utf8_unicode_to_char( $b, $s );

$b.perl.say;

my $cell = TB_Cell.new( :fg(TB_RED), :bg(TB_YELLOW), :ch($b.encode('ISO-8859-1')) );

tb_change_cell( 24, 42, $cell );
tb_present;

sleep 3;

tb_shutdown;
