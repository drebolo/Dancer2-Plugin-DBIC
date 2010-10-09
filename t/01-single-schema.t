use strict;
use warnings;
use Test::More tests => 4, import => ['!pass'];
use Test::Exception;

use Dancer;
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
        }
    };

    unlink $dbfile1, $dbfile2;

    my $dbh1 = DBI->connect("dbi:SQLite:dbname=$dbfile1");

    ok $dbh1->do(q{
        create table user (name varchar(100) primary key, age int)
    }), 'Created sqlite test1 db.';

    my @users = ( ['bob', 2] );
    for my $user (@users) {
        $dbh1->do(q{ insert into user values(?,?) }, {}, @$user);
    }
}

use lib "$RealBin/../lib";
use Dancer::Plugin::DBIC;

my $user = schema->resultset('User')->find('bob');
ok $user, 'Found bob.';
is $user->age => '2', 'Bob is a baby.';

throws_ok { schema('bar')->resultset('User')->find('bob') }
    qr/schema bar is not configured/, 'Missing schema error thrown';

unlink $dbfile1, $dbfile2;
