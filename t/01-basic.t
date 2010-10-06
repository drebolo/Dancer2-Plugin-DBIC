use strict;
use warnings;
use Test::More;

use Dancer;
use Dancer::Test;
use DBI;
use DBIx::Class;
use DBIx::Class::Schema::Loader;
DBIx::Class::Schema::Loader->naming('v6');
use FindBin '$RealBin';

BEGIN {

    eval { require DBD::SQLite };
    if ($@) {
        plan skip_all => 'DBD::SQLite required to run these tests';
    }

    my $dbfile = "$RealBin/test.db";

    set plugins => {
        DBIC => {
            foo => {
                #generate => 1,
                auto_load => 1,
                #pckg => "Foo::Bar",
                schema_class => "Foo::Bar",
                dsn =>  "dbi:SQLite:dbname=$dbfile",
            }
        }
    };

    unlink $dbfile;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

    ok $dbh->do(q{
        create table user (name varchar(100) primary key, age int)
    }), 'Created sqlite test db.';

    my @users = ( ['bob', 30] );
    for my $user (@users) {
        $dbh->do(q{ insert into user values(?,?) }, {}, @$user[0,1]);
    }

}

use lib "$RealBin/../lib";
use Dancer::Plugin::DBIC;

get '/foo' => sub {
    my $user = foo->resultset('User')->find('bob');
    ok $user, 'Found bob.';
    is $user->age => '30', 'Bob is getting old.';
};

response_exists [ get => '/foo' ], 'Route /foo ran';

done_testing;
