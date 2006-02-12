use Test::More;
BEGIN {
    eval { require WWW::Mechanize };
    if($@) {
        plan skip_all => "Can't test WWW::Google::SiteMap::Robot without WWW::Mechanize";
    } else {
        plan tests => 1;
    }
    use_ok('WWW::Google::SiteMap::Robot');
};

#my $robot;
#ok($robot = WWW::Google::SiteMap::Robot->new());
#isa_ok($robot,'WWW::Google::SiteMap::Robot');
