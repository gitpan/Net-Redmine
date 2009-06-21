#line 1
package Test::Cukes;
use strict;
use warnings;
use Exporter::Lite;
use Test::More;
use Test::Cukes::Feature;
use Carp::Assert;

our $VERSION = "0.06";
our @EXPORT = qw(feature runtests Given When Then assert affirm should shouldnt);

our @missing_steps = ();

my $steps = {};
my $feature = {};

sub feature {
    my $caller = caller;
    my $text = shift;

    $feature->{$caller} = Test::Cukes::Feature->new($text)
}

sub runtests {
    my $caller = caller;
    my $feature_text = shift;

    if ($feature_text) {
        $feature->{$caller} = Test::Cukes::Feature->new($feature_text);
    }

    my $total_tests = 0;
    my @scenarios_of_caller = @{$feature->{$caller}->scenarios};

    for my $scenario (@scenarios_of_caller) {
        $total_tests += @{$scenario->steps};
    }

    Test::More::plan(tests => $total_tests);

    for my $scenario (@scenarios_of_caller) {
        my $skip = 0;
        my $skip_reason = "";
        my $gwt;
        my %steps = %{$steps->{$caller} ||{}};
    SKIP:
        for my $step_text (@{$scenario->steps}) {
            my ($pre, $step) = split " ", $step_text, 2;
            Test::More::skip($step, 1) if $skip;

            $gwt = $pre if $pre =~ /(Given|When|Then)/;

            my $found_step = 0;
            for my $step_pattern (keys %steps) {
                my $cb = $steps{$step_pattern};

                if ($step =~ m/$step_pattern/) {
                    eval { $cb->(); };
                    Test::More::ok(!$@, $step_text);

                    if ($@) {
                        Test::More::diag($@);
                        $skip = 1;
                        $skip_reason = "Failed: $step_text";
                    }

                    $found_step = 1;
                    last;
                }
            }

            unless($found_step) {
                $step_text =~ s/^And /$gwt /;
                push @missing_steps, $step_text;
            }
        }
    }

    report_missing_steps();

    return 0;
}

sub report_missing_steps {
    return if @missing_steps == 0;
    Test::More::note("There are missing step definitions, fill them in:");
    for my $step_text (@missing_steps) {
        my ($word, $text) = ($step_text =~ /^(Given|When|Then) (.+)$/);
        my $msg = "\n$word qr/${text}/ => sub {\n    ...\n};\n";
        Test::More::note($msg);
    }
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

#line 224
