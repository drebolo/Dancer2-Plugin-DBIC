# ABSTRACT: DBIx::Class interface for Dancer applications

package Dancer::Plugin::DBIC;

use strict;
use warnings;
use Dancer::Plugin;
use DBIx::Class;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

my  $cfg = plugin_setting;
my  $schemas = {};

=head1 SYNOPSIS

    # Dancer Configuration File
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
    
    # Important Note! We have reversed our policy so that D::P::DBIC will not
    # automatically load your DBIx-Class schemas via
    # DBIx::Class::Schema::Loader. To enable auto loading, use the auto_load
    # parameter:
    plugins:
      DBIC:
        foo:
          auto_load: 1
    
    # Dancer Code File
    use Dancer;
    use Dancer::Plugin::DBIC;

    # Note! You can also declare your connection information with the
    # following syntax:
    plugings:
      DBIC:
        foo:
          schema_class: Foo::Bar
          connect_info:
            - dbi:mysql:db_foo
            - root
            - ***
            -
              RaiseError: 1
              PrintError: 1

    # Calling the `foo` dsn keyword will return a L<DBIx::Class> instance using
    # the database connection specifications associated with the dsn keyword
    # within the Dancer configuration file.
    
    get '/profile/:id' => sub {
        my $users_rs = foo->resultset('Users')->search({
            user_id => params->{id}
        });
        
        template 'user_profile', { user_data => $user_rs->next };
    };

    dance;

Database connection details are read from your Dancer application config - see
below.

=head1 DESCRIPTION

Provides an easy way to obtain a DBIx::Class instance by simply calling a dsn keyword
you define within your Dancer configuration file, this allows your L<Dancer>
application to connect to one or many databases with ease and consistency.

=head1 CONFIGURATION

Connection details will be taken from your Dancer application config file, and
should be specified as stated above, for example: 

    plugins:
      DBIC:
        foo:
          schema_class: "Foo"
          dsn:  "dbi:mysql:db_foo"
          user: "root"
          pass: "****"
          options:
            RaiseError: 1
            PrintError: 1
        bar:
          schema_class: "Bar"
          dsn:  "dbi:SQLite:dbname=./foo.db"

Please use dsn keywords that will not clash with existing L<Dancer> and
Dancer::Plugin::*** reserved keywords. 

Each database configuration *must* have a dsn and schema_class option.
The dsn option
should be the L<DBI> driver connection string less the optional user/pass and
arguments options.
The schema_class option should be a proper Perl package name that
Dancer::Plugin::DBIC will use as a DBIx::Class schema class.
Optionally a database
configuation may have user, pass and options paramters which are appended to the
dsn in list form, i.e. dbi:SQLite:dbname=./foo.db, $user, $pass, $options.

=cut

foreach my $keyword (keys %{ $cfg }) {
    register $keyword => sub {
        my @dsn = ();
        
        my $schema_class = $cfg->{$keyword}{schema_class}
            || $cfg->{$keyword}{pckg}; # pckg is deprecated
        $schema_class =~ s/\-/::/g;

        if ( $cfg->{$keyword}->{connect_info} ) {
            push @dsn, @{ $cfg->{$keyword}->{connect_info} };
        }
        else {
            push @dsn, $cfg->{$keyword}->{dsn}  if $cfg->{$keyword}->{dsn};
            push @dsn, $cfg->{$keyword}->{user} if $cfg->{$keyword}->{user};
            push @dsn, $cfg->{$keyword}->{pass} if $cfg->{$keyword}->{pass};
            push @dsn, $cfg->{$keyword}->{options}
              if $cfg->{$keyword}->{options};
        }

        if ( $cfg->{$keyword}{auto_load}
            || $cfg->{$keyword}{generate}) # generate is deprecated
        {
            make_schema_at( $schema_class, {}, [@dsn], );
        } else {
            eval "use $schema_class";
            if ( my $err = $@ ) {
                die "error while loading $schema_class : $err";
            }
        }

        $schemas->{$keyword} = $schema_class->connect(@dsn)
            unless $schemas->{$keyword};
        
        return $schemas->{$keyword};
    };
}

register_plugin;

1;
