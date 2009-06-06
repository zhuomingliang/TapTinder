#!perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use Data::Dumper;
use File::Spec::Functions;

use Bot::BasicBot::Pluggable;

use lib "$FindBin::Bin/../lib";
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);
use TapTinder::Utils::DB qw(get_connected_schema);


my $help = 0;
my $ver = 2;
my $ibot_id = undef;
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'ver|v=i' => \$ver,
    'ibot_id=i' => \$ibot_id,
);
pod2usage(1) if $help || !$options_ok;
unless ( defined $ibot_id ) {
    print "No ibot_id given.\n";
    pod2usage(1);
}

my $conf = load_conf_multi( undef, 'db' );
croak "Configuration for database is empty.\n" unless $conf->{db};

my $schema = get_connected_schema( $conf->{db} );

my $ibot_row = $schema->resultset('ibot')->find(
    $ibot_id,
    {
        join => 'operator_id',
        '+select' => 'operator_id.irc_nick',
        '+as' => 'operator_irc_nick',
    }
);
croak "Bot with id = $ibot_id not found." unless $ibot_row;
my %ibot = $ibot_row->get_columns;

my $ichannel_rs = $schema->resultset('ichannel')->search(
    { 'ibot_id.ibot_id' => $ibot_id, },
    { join => 'ibot_id', }
);
croak "Channel def for with bot_id = $ibot_id not found." unless $ichannel_rs;
my $ra_ichannels = [];
while ( my $ichannel_row = $ichannel_rs->next ) {
    my %ichannel = $ichannel_row->get_columns;
    push @$ra_ichannels, $ichannel{name};
}

# with useful options. pass any option
# that's valid for Bot::BasicBot.
my $bot = Bot::BasicBot::Pluggable->new(
    nick     => $ibot{nick},
    altnicks => [],
    name     => $ibot{full_name},
    server   => $ibot{server},
    port     => $ibot{port},
    username => $ibot{operator_irc_nick},

    channels => $ra_ichannels,
);

$bot->load("Auth");
$bot->load("TapTinderBot");

my $TapTinderBot_handler = $bot->handler("TapTinderBot");
$TapTinderBot_handler->_db_connect($schema);

$bot->run();

__END__

=head1 NAME

ttbot - Start TapTinder bot.

=head1 SYNOPSIS

perl ttbot.pl [options]

Example:
    perl ttbot.pl --server irc.freenode.org --channel TapTinderBot-test

 Options:
   --help
   --ver .. Verbosity level.
   --ibot_id .. ID to ibot table.

=head1 DESCRIPTION

B<This program> will start ...

=cut
