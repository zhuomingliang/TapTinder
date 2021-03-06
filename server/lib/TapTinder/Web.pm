package TapTinder::Web;

use strict;
use warnings;

use Data::Dumper;

use Catalyst::Runtime '5.70';

use Catalyst qw/
    StackTrace

    Config::Multi
    Static::Simple

    Session
    Session::Store::FastMmap
    Session::State::Cookie
/;

our $VERSION = '0.22';


# Note that settings in web_*.yml take precedence over this.
# Thus configuration details given here can function as a default
# configuration, with a external configuration file acting
# as an override for local deployment.

TapTinder::Web->config(
    'namespace' => '',
    'default_view' => 'TT',
    'Plugin::Config::Multi' => {
        dir => TapTinder::Web->path_to('./conf'),
        prefix => '',
        app_name => 'web',
        extension => 'yml',
    },
    'static' => {
        #logging => 1,
        #debug => 1,
        mime_types => {
            t => 'text/plain', # Show test files, as text plain. BY mime type it si 'application/x-troff'.
        },
    },
    'root' => TapTinder::Web->path_to('root'),
);


TapTinder::Web->setup;


=head1 NAME

TapTinder::Web - TapTinder web server.

=head1 SYNOPSIS

See L<TapTinder::Web>

=head1 DESCRIPTION

TapTinder Web server base class based on Catalyst::Runtime.

=head1 SEE ALSO

L<TapTinder>, L<Catalyst::Runtime>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
