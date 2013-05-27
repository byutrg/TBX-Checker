#basic test file

use strict;
use warnings;
use Test::More 0.88;
plan tests => 3;
use TBX::Checker qw(check);
use FindBin qw($Bin);
use Path::Tiny;

my $corpus_dir = path($Bin, 'corpus');

my ($passed, $messages) = check(path($corpus_dir, 'good.tbx'));
ok($passed, 'good.tbx should check')
	or note explain $messages;

($passed, $messages) = check(path($corpus_dir, 'bad.tbx'));
ok(!$passed, q{bad.tbx shouldn't check});

($passed, $messages) = check(path($corpus_dir, 'good.tbx'), loglevel => 'FINE');
ok($#$messages != 0, 'arguments passed on to jar');