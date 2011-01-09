package App::Spiritbutter::Skin;

use strict;
use warnings;
use Template;

sub new {
  my ($class, $template) = @_;

  die "$template not found" unless -e $template;

  my %result = (
    template => Template->new({
        ABSOLUTE => 1,
    }),
    filename => $template,
);

  bless \%result, $class;
}

sub skin {
    my ($self, $content) = @_;

    if (ref($content) eq 'App::Spiritbutter::Parser') {
        # fair enough, but we have to go round again
        # FIXME: die if >1 entry
        for my $v (values %$content) {
            return $self->skin($v);
        }
        return;
    }

    my $target;

    $self->{'template'}->process($self->{'filename'}, $content, \$target)
                   || die $self->{'template'}->error(), "\n";

   return $target;
}

1;
