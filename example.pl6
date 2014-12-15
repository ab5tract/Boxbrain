use Boxbrain::View::Termbox;

tb_init;

my $cell = TB_Cell.new( :fg(TB_RED), :bg(TB_YELLOW), :ch('❄') );

tb_change_cell( 24, 42, $cell );

tb_shutdown;
