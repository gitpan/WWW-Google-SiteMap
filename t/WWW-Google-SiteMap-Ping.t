use Test::More tests => 5;
BEGIN { use_ok('WWW::Google::SiteMap::Ping') };

my $baseurl = "http://www.example.com";

my $ping = WWW::Google::SiteMap::Ping->new(
	"http://www.google.com/sitemap.xml",
);

is($ping->submit(),1,"One ping succeeded");
my @success = $ping->success;
is(scalar @success,1,"One ping returned by success()");
is($success[0],"http://www.google.com/sitemap.xml","Right URL succeeded");
my @failure = $ping->failure;
is(scalar @failure,0,"No pings returned by failure()");
