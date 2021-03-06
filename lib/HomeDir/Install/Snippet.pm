package HomeDir::Install::Snippet;
use strict;

use base 'HomeDir::Install';
use HomeDir::Config::TextConfig;

use Data::Dumper;

sub comment { "#" } 
sub include_external_cmd_pattern { "source %s " }
sub snippet_mark_pattern  { "%shomedir2:%s:%s snippet: do not modify this line manually" }


sub new
{
    my ( $caller, $params ) = @_;
   
    my $self = {
        snippet => $params->{file},
    };

    bless $self, ref $caller || $caller;
}

sub snippet_lines 
{
    my ( $self ) = @_;
    my $fname = $self->expand_homedir_path( $self->{snippet} );
    open my $fh, "<", $fname
        or die "Can't open snippet $fname : $!\n";
    my @lines = <$fh>;
    close $fh;
    chomp for @lines;
    unshift @lines, $self->snippet_start_mark();
    push @lines, $self->snippet_end_mark();
    return \@lines;
}

sub snippet_mark
{
    my ( $self, $label ) = @_;
    sprintf $self->snippet_mark_pattern(), $self->comment(), $self->{snippet}, $label;
}

sub snippet_start_mark
{
    my ( $self ) = @_;
    $self->snippet_mark('start');
}

sub snippet_end_mark
{
    my ( $self ) = @_;
    $self->snippet_mark('end');
}


sub search_positions
{
    my ( $self, $config ) = @_;
    my $pos_start = undef;
    my $pos_end = undef;
    my $re = $self->snippet_start_mark()."\$";
    my $config_lines = $config->lines();
    my $i = 0; 
    foreach my $line (@$config_lines) {
        if ( $line =~ /$re/ ) {
            if( !defined $pos_start ) {
                $pos_start = $i;
                $re = $self->snippet_end_mark()."\$";
            } else {
                $pos_end = $i;
                last;
            }
        } 
        $i++;
    }
    return $pos_start, $pos_end;
}

sub install
{
    my ($self, $config) = @_;
    my $config_lines = $config->lines();
    my ($pos_start, $pos_end) = $self->search_positions( $config );
    if( !defined $pos_start ) {
        push @$config_lines, @{$self->snippet_lines()};
    } elsif( defined $pos_start &&  defined $pos_end ) {
        splice @$config_lines, $pos_start, ($pos_end - $pos_start + 1), @{$self->snippet_lines()}
    } else {
        warn "Snippet $self->{snippet} is corrupted in ".$config->full_path().", won't install it\n";
    }
}
1;

