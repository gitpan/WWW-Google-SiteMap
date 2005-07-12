use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> 'WWW::Google::SiteMap',
	VERSION_FROM		=> 'lib/WWW/Google/SiteMap.pm',
	PREREQ_PM			=> {
		'XML::Twig'			=> 0,
		'IO::File'			=> 0,
	},
	($] >= 5.005 ? (
		ABSTRACT_FROM	=> 'lib/WWW/Google/SiteMap.pm',
		AUTHOR			=> 'Jason Kohles <email@jasonkohles.com>'
	) : ()),
);
