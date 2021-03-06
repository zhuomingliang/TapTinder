package TapTinder::Utils::DB;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base 'Exporter';
our @EXPORT = qw(get_connected_schema do_dbh_sql get_dbh_errstr);

use TapTinder::DB::SchemaAdd;

=head2 get_connected_schema

 TapTinder::DB::SchemaAdd->connect(...)

=cut

sub get_connected_schema {
    my ( $db_conf ) = @_;

    my $schema = TapTinder::DB::SchemaAdd->connect(
        $db_conf->{dbi_dsn},
        $db_conf->{user},
        $db_conf->{pass},
        { AutoCommit => 1 },
    );
    return $schema;
}


=head2 get_drop_sql_list

Connect to DB. Take list of DB tables. Return list of sql statements to drop all these tables.

=cut

sub get_drop_sql_list {
    my ( $schema ) = @_;
    
    my $dbh = $schema->storage->dbh;
    my @tables = $dbh->tables();
    
    my @sql_list = ();
    push @sql_list, "SET foreign_key_checks=0;";
    foreach my $table_name ( @tables ) {
        push @sql_list, "DROP TABLE IF EXISTS $table_name;";
    }
    push @sql_list, "SET foreign_key_checks=1;";
    return @sql_list;
}


=head2 get_drop_all_existing_tables_sql

Connect to DB. Take list of DB tables. Return sql to drop all these tables.

=cut

sub get_drop_all_existing_tables_sql {
    my ( $schema ) = @_;

    my @sql_list = get_drop_sql_list( $schema );
    my $drop_sql = join("\n", @sql_list) . "\n";
    return $drop_sql;
}


=head2 do_drop_all_existing_tables

Connect to DB. Take list of DB tables. Drop all these tables.

=cut

sub do_drop_all_existing_tables {
    my ( $schema ) = @_;

    my @sql_list = get_drop_sql_list( $schema );

    my $dbh = $schema->storage->dbh;
    foreach my $statement ( @sql_list ) {
        $dbh->do($statement) or croak $dbh->errstr;
    }
    return 1;
}


=head2 run_perl_sql_file

Run script to fill data to database (sql/data-*.pl).

=cut

sub run_perl_sql_file {
    my $req_fpath = shift;
    # Others from @_ used below.

    carp "File '$req_fpath' doesn't exists." unless -f $req_fpath;
    my $do_sub = require $req_fpath;
    if ( ref $do_sub ne 'CODE' ) {
        carp "No code reference returned from '$req_fpath'.";
        return 0;
    }
    return $do_sub->( @_ );
}

=head2 get_dbh_errstr

Return dbh error string;

=cut


sub get_dbh_errstr {
    my ( $schema ) = @_;
    return $schema->storage->dbh->errstr;
}


=head2 do_dbh_sql

Run $sql, $ba on $schema throug dbh_do (DBI do).

=cut

sub do_dbh_sql {
    my ( $schema, $sql, $ba ) = @_;
    
    my $data = $schema->storage->dbh_do(
        sub { 
            my $data = undef;
            eval { 
                $data = $_[1]->do( $_[2], {}, @{$_[3]} ); 
            };
            return $data;
        },
        $sql,
        $ba
    );
    return 0 unless $data;
    return 1;
}


1;