# ABSTRACT: DBIx::Class interface for Dancer applications

package Dancer::Plugin::DBIC;

use strict;
use warnings;
use Dancer::Plugin;
use DBIx::Class;
use DBIx::Class::Schema::Loader;

my  $cfg = plugin_setting;
my  $schemas = {};

=head1 SYNOPSIS

    # Dancer Configuration File
    plugins:
      DBIC:
        foo:
          dsn:  "dbi:SQLite:dbname=./foo.db"
        bar:
          dsn:  "dbi:mysql:db_foo"
          user: "root"
          pass: "****"
          options:
            RaiseError: 1
            PrintError: 1
    
    # Dancer Code File
    use Dancer;
    use Dancer::Plugin::DBIC;

    # Calling foo or bar will return a DBIx::Class::Schema instance using
    # the database connection info from the configuration file.
    
    get '/profile/:id' => sub {
        my $user = foo->resultset('Users')->find(params->{id});
        template user_profile => { user => $user };
    };

    dance;

Database connection details are read from your Dancer application config - see
below.

=head1 DESCRIPTION

Provides an easy way to obtain DBIx::Class::ResultSet instances.
You just need to point to a dsn in your L<Dancer> configuration file.
So you no longer have to write boilerplate DBIC setup code.

=head1 CONFIGURATION

Connection details will be taken from your Dancer application config file, and
should be specified as stated above, for example: 

    plugins:
      DBIC:
        foo:
          schema_class: "Foo::Bar"
          dsn:  "dbi:mysql:db_foo"
          user: "root"
          pass: "****"
          options:
            RaiseError: 1
            PrintError: 1
        bar:
          dsn:  "dbi:SQLite:dbname=./foo.db"

Make sure that the options immediately under DBIC
(foo and bar in the above example)
do not clash with existing L<Dancer> and Dancer::Plugin::*** reserved keywords. 

Each database configuration *must* have a dsn option.
The dsn option should be the L<DBI> driver connection string.

If a schema_class option is not provided, then L<DBIx::Class::Schema::Loader>
will be used to auto load the schema.

The schema_class option, if provided, should be a proper Perl package name that
Dancer::Plugin::DBIC will use as a DBIx::Class::Schema class.
Optionally, a database configuation may have user, pass and options paramters
which are appended to the dsn in list form,
i.e. dbi:SQLite:dbname=./foo.db, $user, $pass, $options.

    # Note! You can also declare your connection information with the
    # following syntax:
    plugings:
      DBIC:
        foo:
          connect_info:
            - dbi:mysql:db_foo
            - root
            - ***
            -
              RaiseError: 1
              PrintError: 1

=cut

#use Data::Dumper;
register schema => sub {
    my $name = shift;

    return $schemas->{$name} if $schemas->{$name};
    my $options = defined $name ? $cfg->{$name} : (each %$cfg)[1];
    die "The schema $name is not configured" unless $options;

    my @conn_info = $options->{connect_info}
        ? @{$options->{connect_info}}
        : @$options{qw(dsn user pass options)};

    # pckg should be deprecated
    my $schema_class = $options->{schema_class} || $options->{pckg};

    if ($schema_class) {
        $schema_class =~ s/-/::/g;
        eval "use $schema_class";
        if ( my $err = $@ ) {
            die "error while loading $schema_class : $err";
        }
        $schemas->{$name} = $schema_class->connect(@conn_info)
    } else {
        $schemas->{$name} = DBIx::Class::Schema::Loader->connect(@conn_info);
    }

    return $schemas->{$name};
};

register_plugin;

1;
