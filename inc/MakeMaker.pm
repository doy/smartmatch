package inc::MakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my $self = shift;

    my $tmpl = super;

    my $depends = <<'END';
%WriteMakefileArgs = (
    %WriteMakefileArgs,
    ExtUtils::Depends->new('smartmatch', 'B::Hooks::OP::Check')->get_makefile_vars,
);
END

    $tmpl =~ s/(use ExtUtils.*)/$1\nuse ExtUtils::Depends;/;
    $tmpl =~ s/(WriteMakefile\()/$depends\n$1/;

    return $tmpl;
};

__PACKAGE__->meta->make_immutable;
1;
