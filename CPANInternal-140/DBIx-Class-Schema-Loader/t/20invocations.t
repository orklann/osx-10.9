use strict;
use Test::More;
use lib qw(t/lib);
use make_dbictest_db;

local $SIG{__WARN__} = sub {
    warn $_[0] unless $_[0] =~ /really_erase_my_files/
};

# Takes a $schema as input, runs 4 basic tests
sub test_schema {
    my ($testname, $schema) = @_;

    $schema = $schema->clone if !ref $schema;
    isa_ok($schema, 'DBIx::Class::Schema', $testname);

    my $foo_rs = $schema->resultset('Bar')->search({ barid => 3})->search_related('fooref');
    isa_ok($foo_rs, 'DBIx::Class::ResultSet', $testname);

    my $foo_first = $foo_rs->first;
    like(ref $foo_first, qr/DBICTest::Schema::\d+::Foo/, $testname);

    my $foo_first_text = $foo_first->footext;
    is($foo_first_text, 'Foo record associated with the Bar with barid 3');
}

my @invocations = (
    'hardcode' => sub {
        package DBICTest::Schema::5;
        use base qw/ DBIx::Class::Schema::Loader /;
        __PACKAGE__->naming('current');
        __PACKAGE__->connection($make_dbictest_db::dsn);
        __PACKAGE__;
    },
    'normal' => sub {
        package DBICTest::Schema::6;
        use base qw/ DBIx::Class::Schema::Loader /;
        __PACKAGE__->loader_options();
        __PACKAGE__->naming('current');
        __PACKAGE__->connect($make_dbictest_db::dsn);
    },
    'make_schema_at' => sub {
        use DBIx::Class::Schema::Loader qw/ make_schema_at /;
        make_schema_at(
            'DBICTest::Schema::7',
            { really_erase_my_files => 1, naming => 'current' },
            [ $make_dbictest_db::dsn ],
        );
        DBICTest::Schema::7->clone;
    },
    'embedded_options' => sub {
        package DBICTest::Schema::8;
        use base qw/ DBIx::Class::Schema::Loader /;
        __PACKAGE__->naming('current');
        __PACKAGE__->connect(
            $make_dbictest_db::dsn,
            { loader_options => { really_erase_my_files => 1 } }
        );
    },
    'embedded_options_in_attrs' => sub {
        package DBICTest::Schema::9;
        use base qw/ DBIx::Class::Schema::Loader /;
        __PACKAGE__->naming('current');
        __PACKAGE__->connect(
            $make_dbictest_db::dsn,
            undef,
            undef,
            { AutoCommit => 1, loader_options => { really_erase_my_files => 1 } }
        );
    },
    'embedded_options_make_schema_at' => sub {
        use DBIx::Class::Schema::Loader qw/ make_schema_at /;
        make_schema_at(
            'DBICTest::Schema::10',
            { },
            [
                $make_dbictest_db::dsn,
                { loader_options => {
                    really_erase_my_files => 1,
                    naming => 'current'
                } },
            ],
        );
        "DBICTest::Schema::10";
    },
    'almost_embedded' => sub {
        package DBICTest::Schema::11;
        use base qw/ DBIx::Class::Schema::Loader /;
        __PACKAGE__->loader_options(
            really_erase_my_files => 1,
            naming => 'current'
        );
        __PACKAGE__->connect(
            $make_dbictest_db::dsn,
            undef, undef, { AutoCommit => 1 }
        );
    },
    'make_schema_at_explicit' => sub {
        use DBIx::Class::Schema::Loader;
        DBIx::Class::Schema::Loader::make_schema_at(
            'DBICTest::Schema::12',
            { really_erase_my_files => 1, naming => 'current' },
            [ $make_dbictest_db::dsn ],
        );
        DBICTest::Schema::12->clone;
    },
    'skip_load_external_1' => sub {
        # By default we should pull in t/lib/DBICTest/Schema/13/Foo.pm $skip_me since t/lib is in @INC
        use DBIx::Class::Schema::Loader;
        DBIx::Class::Schema::Loader::make_schema_at(
            'DBICTest::Schema::13',
            { really_erase_my_files => 1, naming => 'current' },
            [ $make_dbictest_db::dsn ],
        );
        DBICTest::Schema::13->clone;
    },
    'skip_load_external_2' => sub {
        # When we explicitly skip_load_external t/lib/DBICTest/Schema/14/Foo.pm should be ignored
        use DBIx::Class::Schema::Loader;
        DBIx::Class::Schema::Loader::make_schema_at(
            'DBICTest::Schema::14',
            { really_erase_my_files => 1, naming => 'current', skip_load_external => 1 },
            [ $make_dbictest_db::dsn ],
        );
        DBICTest::Schema::14->clone;
    },
);

# 4 tests per k/v pair
plan tests => 2 * @invocations + 2;  # + 2 more manual ones below.

while(@invocations >= 2) {
    my $style = shift @invocations;
    my $subref = shift @invocations;
    test_schema($style, &$subref);
}

{
    no warnings 'once';

    is($DBICTest::Schema::13::Foo::skip_me, "bad mojo",
        "external content loaded");
    is($DBICTest::Schema::14::Foo::skip_me, undef,
        "external content not loaded with skip_load_external => 1");
}
