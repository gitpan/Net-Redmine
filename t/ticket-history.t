#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;

require 't/net_redmine_test.pl';
my $r = new_net_redmine();

plan tests => 6;

### Prepare a new ticket with multiple histories
my $t = $r->create(
    ticket => {
        subject => __FILE__ . " 1",
        description => __FILE__ . " (description)"
    }
);

$t->subject( $t->subject . " 2" );
$t->save;

$t->subject( $t->subject . " 3" );
$t->note("it is good. " . time);
$t->save;

diag "Created a new ticket, id = " . $t->id;

### Examine its histories

use Net::Redmine::TicketHistory;

{
    my $h = Net::Redmine::TicketHistory->new(
        connection => $r->connection,
        id => 1,
        ticket_id => $t->id
    );

    my $prop = $h->property_changes;

    is_deeply(
        $prop->{subject},
        {
            from => __FILE__ . " 1",
            to => __FILE__ . " 1 2",
        }
    );
}

{
    my $h = Net::Redmine::TicketHistory->new(
        connection => $r->connection,
        id => 2,
        ticket_id => $t->id
    );

    like $h->note, qr/it is good. \d+/;

    my $prop = $h->property_changes;

    is_deeply(
        $prop->{subject},
        {
            from => __FILE__ . " 1 2",
            to => __FILE__ . " 1 2 3",
        }
    );
}

{
    my $histories = $t->histories;
    is(0+@$histories, 2, "This ticket has two history entires");

    is_deeply(
        $histories->[0]->property_changes->{subject},
        {
            from => __FILE__ . " 1",
            to => __FILE__ . " 1 2",
        }
    );

    is_deeply(
        $histories->[1]->property_changes->{subject},
        {
            from => __FILE__ . " 1 2",
            to => __FILE__ . " 1 2 3",
        }
    );
}
