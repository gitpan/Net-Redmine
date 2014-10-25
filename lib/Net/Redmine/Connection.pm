package Net::Redmine::Connection;
use Any::Moose;

has url      => ( is => "rw", isa => "Str", required => 1 );
has user     => ( is => "rw", isa => "Str", required => 1 );
has password => ( is => "rw", isa => "Str", required => 1 );

has mechanize => (
    is => "rw",
    isa => "WWW::Mechanize",
    lazy_build => 1,
);

use WWW::Mechanize;

sub _build_mechanize {
    my ($self) = @_;
    my $mech = WWW::Mechanize->new;
    return $mech;
}

sub get_project_overview {
    my ($self) = @_;
    my $mech = $self->mechanize;

    $mech->get( $self->url );

    if ($mech->uri =~ /\/login/) {
        $mech->submit_form(
            form_number => 2,
            fields => {
                username => $self->user,
                password => $self->password
            }
        );

        if ($mech->uri ne $self->url) {
            $mech->get($self->url);
        }
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;

__END__

=head1 NAME

Net::Redmine::Connection

=head1 SYNOPSIS

    # Initialize a redmien connection object
    my $redmine = Net::Redmine::Connection->new(
        url => 'http://redmine.example.com/projects/show/fooproject'
        user => 'hiro',
        password => 'yatta'
    );

    # Passed it to other classes
    my $ticket = Net::Redmine::Ticket->new(connection => $redmine);

=head1 DESCRIPTION



=cut

