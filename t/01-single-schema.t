use strict;
use warnings;
use Test::More tests => 4, import => ['!pass'];
use Test::Exception;

use Dancer ':syntax';

use File::Spec;
use File::Temp qw/tempdir/;

use DBI;
use FindBin '$RealBin';

eval { require DBD::SQLite };
if ($@) {
    plan skip_all => 'DBD::SQLite required to run these tests';
}

my $dir = tempdir( CLEANUP => 1 );
my $dbfile = File::Spec->catfile( $dir, 'test.db' );

set plugins => {
    DBIC => {
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
        },
    }
};

my $dbh1 = DBI->connect("dbi:SQLite:dbname=$dbfile");

ok $dbh1->do(q{
    create table user (name varchar(100) primary key, age int)
}), 'Created sqlite test1 db.';

my @users = ( ['bob', 2] );
for my $user (@users) { $dbh1->do('insert into user values(?,?)', {}, @$user) }

use lib "$RealBin/../lib";
use Dancer::Plugin::DBIC;

my $user = schema->resultset('User')->find('bob');
ok $user, 'Found bob.';
is $user->age => '2', 'Bob is a baby.';

throws_ok { schema('bar')->resultset('User')->find('bob') }
    qr/schema bar is not configured/, 'Missing schema error thrown';
