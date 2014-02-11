use strict;
use warnings;
package Dist::Zilla::Plugin::Breaks;
# ABSTRACT: Add metadata about potential breakages to your distribution
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use CPAN::Meta::Requirements;
use version;
use namespace::autoclean;

sub mvp_multivalue_args { qw(breaks) }

has breaks => (
    is => 'ro', isa => 'HashRef[Str]',
    required => 1,
);

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    my ($zilla, $plugin_name) = delete @{$args}{qw(zilla plugin_name)};

    confess "Missing modules in [Breaks]" if not keys %$args;

    return {
        zilla => $zilla,
        plugin_name => $plugin_name,
        breaks => $args,
    };
};

# nothing to put in dump_config yet...
# around dump_config => sub { ... };

sub metadata
{
    my $self = shift;

    my $reqs = CPAN::Meta::Requirements->new;
    my $breaks_data = $self->breaks;
    foreach my $package (keys %$breaks_data)
    {
        $self->log('version without range specified. Did you intend to specify that any version of '
                . $package . ' at or above '. $breaks_data->{$package}
                . ' is bad?')
            if version::is_lax($breaks_data->{$package});

        # this validates input data, and canonicalizes formatting
        $reqs->add_string_requirement($package, $breaks_data->{$package});
    }

    $breaks_data = $reqs->as_string_hash;
    return keys %$breaks_data ? { x_breaks => $breaks_data } : {};
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

    In your F<dist.ini>:

    [Breaks]
    Foo::Bar = <= 1.0       ; anything at this version or below is out of date
    Foo::Baz = == 2.35      ; just this one exact version is problematic

=head1 DESCRIPTION

This plugin adds distribution metadata regarding other modules and version
that are not compatible with your distribution's release.  It is not quite the
same as the C<conflicts> field in prerequisite metadata (see
L<https://metacpan.org/pod/CPAN::Meta::Spec#Relationships>), but rather
indicates what modules will likely not work once your distribution is
installed.

=for stopwords darkPAN

This is a not-uncommon problem when modifying a module's API - there are other
existing modules out on the CPAN (or a darkPAN) which use the old API, and will
need to be updated when the new API is removed.  These modules are not
prerequisites -- our distribution does not use those modules, but rather those
modules use B<us>. So, it's not valid to list those modules in our
prerequisites -- besides, it would likely be a circular dependency!

The data is added to metadata in the form of the C<x_breaks> field, as set out
by the L<Lancaster consensus|http://www.dagolden.com/index.php/2098/the-annotated-lancaster-consensus/>.
The exact syntax and use may continue to change until it is accepted as an
official part of the meta specification.

Version ranges can and should normally be specified; see
L<https://metacpan.org/pod/CPAN::Meta::Spec#Version-Ranges>. They are
interpreted as for C<conflicts> -- version(s) specified indicate the B<bad>
versions of modules, not version(s) that must be present for normal operation.
That is, packages should be specified with the version(s) that will B<not>
work when your distribution is installed; for example, if all version of
C<Foo::Bar> up to and including 1.2 will break, but a release of 1.3 will
work, then specify the breakage as:

    [Breaks]
    Foo::Bar = <= 1.2

or more accurately:

    [Breaks]
    Foo::Bar = < 1.3

=for stopwords CheckBreaks

The L<[CheckBreaks]|Dist::Zilla::Plugin::Test::CheckBreaks> plugin can
generate a test for your distribution that will check this field and provide
diagnostic information to the user should any problems be identified.

Additionally, the L<[Conflicts]|Dist::Zilla::Plugin::Conflicts> plugin can
generate C<x_breaks> data, as well as a mechanism for checking for conflicts
from within F<Makefile.PL>/F<Build.PL>.

=for Pod::Coverage mvp_multivalue_args metadata

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Breaks>
(or L<bug-Dist-Zilla-Plugin-Breaks@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Breaks@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=begin :list

* L<Annotated Lancaster consensus|http://www.dagolden.com/index.php/2098/the-annotated-lancaster-consensus/>.
* L<https://metacpan.org/pod/CPAN::Meta::Spec#Relationships>
* L<Dist::Zilla::Plugin::Test::CheckBreaks>
* L<Dist::Zilla::Plugin::Conflicts>
* L<Dist::CheckConflicts>

=end :list

=cut
