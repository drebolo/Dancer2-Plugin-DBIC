use strict;
use warnings;
use Test::More tests => 8;

use Dancer;
use Dancer::Test;
use DBI;
use DBIx::Class;
use DBIx::Class::Schema::Loader;
DBIx::Class::Schema::Loader->naming('v6');
use FindBin '$RealBin';

my $dbfile1;
my $dbfile2;

BEGIN {

    eval { require DBD::SQLite };
    if ($@) {
        plan skip_all => 'DBD::SQLite required to run these tests';
    }

    $dbfile1 = "$RealBin/test1.db";
    $dbfile2 = "$RealBin/test2.db";

    set plugins => {
        DBIC => {
            foo => {
                dsn =>  "dbi:SQLite:dbname=$dbfile1",
            },
            bar => {
                dsn =>  "dbi:SQLite:dbname=$dbfile2",
            },
        }
    };

    unlink $dbfile1, $dbfile2;

    my $dbh1 = DBI->connect("dbi:SQLite:dbname=$dbfile1");

    ok $dbh1->do(q{
        create table user (name varchar(100) primary key, age int)
    }), 'Created sqlite test1 db.';

    my @users = ( ['bob', 30] );
    for my $user (@users) {
        $dbh1->do(q{ insert into user values(?,?) }, {}, @$user[0,1]);
    }

    my $dbh2 = DBI->connect("dbi:SQLite:dbname=$dbfile2");

    ok $dbh2->do(q{
        create table user (name varchar(100) primary key, age int)
    }), 'Created sqlite test2 db.';

    @users = ( ['sue', 20] );
    for my $user (@users) {
        $dbh2->do(q{ insert into user values(?,?) }, {}, @$user[0,1]);
    }

}

use lib "$RealBin/../lib";
use Dancer::Plugin::DBIC;

get '/bob' => sub {
    my $user = foo->resultset('User')->find('bob');
    ok $user, 'Found bob.';
    is $user->age => '30', 'Bob is getting old.';
};

get '/sue' => sub {
    my $user = bar->resultset('User')->find('sue');
    ok $user, 'Found sue.';
    is $user->age => '20', 'Sue is the right age.';
};

response_exists [ get => '/bob' ], 'Route /bob ran';

response_exists [ get => '/sue' ], 'Route /sue ran';

unlink $dbfile1, $dbfile2;

#done_testing;
