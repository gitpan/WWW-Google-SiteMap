use Test::More tests => 4;
BEGIN { use_ok('WWW::Google::SiteMap::URL') };

my $url = WWW::Google::SiteMap::URL->new();

time_test('epoch time 1','1133128421','2005-11-27T21:53:41+00:00');
time_test('ISO8601 1','2005-11-27T21:55:51+00:00','2005-11-27T21:55:51+00:00');

eval "use DateTime";
my $HAVE_DateTime = $DateTime::VERSION;
SKIP: {
	skip "Need DateTime to test DateTime conversions", 1 unless $HAVE_DateTime;
	my $dt1 = DateTime->from_epoch(epoch => 1133128421);
	time_test('DateTime 1',$dt1,'2005-11-27T21:53:41+00:00');
};

sub time_test {
	my($id,$from,$to) = @_;
	my $url = WWW::Google::SiteMap::URL->new(
		loc		=> 'http://www.example.com/',
		lastmod	=> $from,
	);
	is($url->lastmod,$to,"lastmod check: $id ($from -> $to)");
}
