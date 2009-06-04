#line 1
package Test::Cukes;
use strict;
use warnings;
use Exporter::Lite;
use Test::More;
use Test::Cukes::Feature;
use Carp::Assert;

our $VERSION = "0.03";
our @EXPORT = qw(feature runtests Given When Then assert affirm should shouldnt);

my $steps = {};
my $feature = {};

sub feature {
    my $caller = caller;
    my $text = shift;

    $feature->{$caller} = Test::Cukes::Feature->new($text)
}

sub runtests {
    my $caller = caller;
    my $total_tests = 0;
    for my $scenario (@{$feature->{$caller}->scenarios}) {
        $total_tests += @{$scenario->steps};
    }

    Test::More::plan(tests => $total_tests);

    my $skip = 0;
    my $skip_reason = "";
    for my $scenario (@{$feature->{$caller}->scenarios}) {
        my %steps = %{$steps->{$caller}};
        for my $step_text (@{$scenario->steps}) {
            my (undef, $step) = split " ", $step_text, 2;

        SKIP:
            while (my ($step_pattern, $cb) = each %steps) {
                Test::More::skip($step, 1) if $skip;

                if ($step =~ m/$step_pattern/) {
                    eval { $cb->(); };
                    Test::More::ok(!$@, $step_text);

                    if ($@) {
                        Test::More::diag($@);
                        $skip = 1;
                        $skip_reason = "Failed: $step_text";
                    }
                    next;
                }
            }
        }
    }

    return 0;
}

sub _add_step {
    my ($step, $cb) = @_;
    my $caller = caller;
    $steps->{$caller}{$step} = $cb;
}

*Given = *_add_step;
*When = *_add_step;
*Then = *_add_step;

1;
__END__

#line 190
