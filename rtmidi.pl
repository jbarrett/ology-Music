#!/usr/bin/env perl

# This works on my mac with Logic Pro X. Untested elsewhere.

use strict;
use warnings;

use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(MIDI-Util);
use MIDI::Util qw(setup_score);
use Getopt::Long qw(GetOptions);
use MIDI::RtMidi::FFI::Device;

my %opt = (
    virtual  => 'perl-rtmidi',
    named    => 'Logic Pro Virtual In',
    duration => -1, # -1 = random select from pool. 'qn' = quarter-note, etc.
);
GetOptions(\%opt,
    'virtual=s',
    'port=s',
    'duration=s',
);

my @durations = qw(wn hn qn en sn);

my $score = setup_score();

# add notes to the score
for my $pitch (qw(C5 G4 F4 C4)) {
    my $duration = $opt{duration} eq '-1' ? $durations[int rand @durations] : $opt{duration};
    $score->n($duration, $pitch);
}

# convert the score to an event list
my $events = MIDI::Score::score_r_to_events_r($score->{Score});

# fire up RT-MIDI!
my $device = RtMidiOut->new;
$device->open_virtual_port($opt{virtual});
$device->open_port_by_name($opt{named});

# send the events to the open port
for my $event (@$events) {
    if ($event->[0] =~ /^(note_\w+)$/) {
        my $op = $1;
        $device->send_event($op => @{ $event }[ 2 .. 4 ]);
        sleep 1 if $op eq 'note_on';
    }
}
