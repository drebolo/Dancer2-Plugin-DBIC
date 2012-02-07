# ABSTRACT: DBIx::Class interface for Dancer applications

package Dancer::Plugin::DBIC;

use strict;
use warnings;
use Dancer::Plugin;
use DBIx::Class;
use DBIx::Class::Schema::Loader;
DBIx::Class::Schema::Loader->naming('v7');

=head1 SYNOPSIS

    # Dancer Code File
    use Dancer;
    use Dancer::Plugin::DBIC;

    get '/profile/:id' => sub {
        my $user = schema->resultset('Users')->find(params->{id});
        # or explicitly ask for a schema by name:
        $user = schema('foo')->resultset('Users')->find(params->{id});
        template user_profile => { user => $user };
    };

    dance;

    # Dancer config file (config.yml) or environments/*.yml
    plugins:
      DBIC:
        dsn:  "dbi:SQLite:dbname=./foo.db"
        schema_class: "My::Schema"

If you're using multiple database connections or schemas, you can also provide
them with names, then pass the corresponding name to C<schema> to get the
appropriate one:

    plugins:
      DBIC:
        foo:
          dsn: "dbi:SQLite:dbname=foo.db"
        bar:
          dsn: "dbi:SQLite:dbname=bar.db"

See below for more detailed configuration examples.


=head1 DESCRIPTION

This plugin provides an easy way to obtain L<DBIx::Class::ResultSet> instances
via the provided C<schema> keyword, which it automatically exports.

You just need to put your database connection details in your L<Dancer> 
configuration file, generate schema classes by hand or using L<dbicdump> (or
allow the plugin to automatically take care of that by using
L<DBIx::Class::Schema::Loader> - but this isn't recommended for production use),
and you're ready to go.


=head1 CONFIGURATION

Connection details will be grabbed from your L<Dancer> config file.
For example: 

    plugins:
      DBIC:
        foo:
          dsn: dbi:SQLite:dbname=./foo.db
        bar:
          schema_class: Foo::Bar
          dsn:  dbi:mysql:db_foo
          user: root
          pass: secret
          options:
            RaiseError: 1
            PrintError: 1

Each schema configuration *must* have a dsn option.
The dsn option should be the L<DBI> driver connection string.
All other options are optional.

If a schema_class option is not provided, then L<DBIx::Class::Schema::Loader>
will be used to auto load the schema based on the dsn value - but see below for
caveats.

The schema_class option, if provided, should be a proper Perl package name that
Dancer::Plugin::DBIC will use as a DBIx::Class::Schema class.
Optionally, a database configuation may have user, pass and options paramters
as described in the documentation for connect() in L<DBI>.

    # Note: You can also declare your connection information with the
    # following syntax:
    plugins:
      DBIC:
        foo:
          connect_info:
            - dbi:mysql:db_foo
            - root
            - secret
            -
              RaiseError: 1
              PrintError: 1

=head1 SCHEMA GENERATION

This plugin provides flexibility in defining schemas for use in your Dancer 
applications. Schemas can be generated manually by you and defined in your 
configuration file using the C<schema_class> setting as illustrated above, which
is the recommended approach for performance and stability.

It is also possible to have schema classes automatically generated via
introspection (powered by L<DBIx::Class::Schema::Loader>) if you omit the
C<schema_class> directive; this is not encouraged for production use, however.

You can, of course, use the L<dbicdump> command-line utility provided by
L<DBIx::Class::Schema::Loader> to ease the generation of your schema classes.

=cut

my $schemas = {};

register schema => sub {
    my $name = shift;
    my $cfg = plugin_setting;

    if (not defined $name) {
        ($name) = keys %$cfg or die "No schemas are configured";
    }

    return $schemas->{$name} if $schemas->{$name};

    my $options = $cfg->{$name} or die "The schema $name is not configured";

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
