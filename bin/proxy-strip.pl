#!/usr/bin/perl -w
#
# #Id$
#
# proxy-strip.pl - a stripping proxy server
#
# Cobbled together by bmc@shmoo.com
#
# much of this was ripped from the Perl Cookbook.

use strict;
use POSIX;
use IO::Select;
use IO::Socket::INET;
use Fcntl;
use Tie::RefHash;
use Getopt::Long;

my @getopt_args = ('help|?', 'listenport=s', 'remoteip=s', 'remoteport=s', 'strip_from_client=s@', 'strip_from_server=s@', 'debug|v');
my %options = (remoteip => '127.0.0.1', remoteport => 2501, listenport => 9999);
GetOptions(\%options, @getopt_args);

sub usage {
    print "$0 -listenport <PORT> -remoteport <PORT> -remoteip <IP>\n";
    print "  [-strip_from_client <REGEX>] ... [-strip_from_client <REGEX>]\n";
    print "  [-strip_from_server <REGEX>] ... [-strip_from_server <REGEX>]\n";
    exit;
}
usage() if ($options{'help'});

# start server
my $server = IO::Socket::INET->new(
    LocalPort => $options{'listenport'},
    Listen    => 100,
    Reuse     => 1
  )
  or die "Can't make server socket: $@\n";

# begin with empty buffers
my %inbuffer  = ();
my %outbuffer = ();
my %ready     = ();
my %clients   = ();
my %sockets = ();

tie %ready, 'Tie::RefHash';

nonblock($server);
my $select = IO::Select->new();
$select->add($server);

# Main loop: check reads/accepts, check writes, check ready to process
while (1) {
    # anything to read or accept?
    foreach my $connection ($select->can_read(1)) {
        # accept a new connection
        if ($connection == $server) {
            add_client($connection);
        } else {

            # read data
            my $data;
            my $rv = $connection->recv($data, POSIX::BUFSIZ, 0);

            unless (defined($rv) && length $data) {
                remove_connection($connection);
                next;
            }

            $inbuffer{$connection} .= $data;

            # process each line as a seperate request, only passing on full lines
            while ($inbuffer{$connection} =~ s/(.*\n)//) {
                push(@{ $ready{$connection} }, $1);
            }
        }
    }

    # Any complete requests to process?
    foreach my $connection (keys %ready) {
        handle($connection);
    }

    # Buffers to flush?
    foreach my $connection ($select->can_write(1)) {

        # Skip this client if we have nothing to say
        next unless exists $outbuffer{$connection};

        my $rv = $connection->send($outbuffer{$connection}, 0);
        unless (defined $rv) {
            # Whine, but move on.
            warn "I was told I could write, but I can't.\n";
            next;
        }
        if ($rv == length $outbuffer{$connection} || $! == POSIX::EWOULDBLOCK) {
            substr($outbuffer{$connection}, 0, $rv) = '';
            delete $outbuffer{$connection} unless length $outbuffer{$connection};
        } else {
            remove_connection($connection);
            next;
        }
    }
}

# remove a given connection (Both sides)
sub remove_connection {
    my ($c) = @_;

    if ($sockets{$c}{'type'} =~ /^client$/) {
        remove_socket($sockets{$c}{'server'});
    } elsif ($sockets{$c}{'type'} =~ /^server$/) {
        remove_socket($sockets{$c}{'client'});
    } else {
        die "ACK unknown type : $sockets{$c}{'type'}\n";
    }

    remove_socket($c);
}

sub remove_socket {
    my ($c) = @_;
    
    delete $inbuffer{$c};
    delete $outbuffer{$c};
    delete $ready{$c};
    delete $sockets{$c};
    $select->remove($c);
    close($c);
}

# add a client to the list of things we handle
sub add_client {
    my ($connection) = @_;
    $connection = $server->accept();
    nonblock($connection);

    $select->add($connection);
    $sockets{$connection}{'type'} = 'client';
   
    # each client gets a new connection the server we are proxing to...
    my $remote = IO::Socket::INET->new(
            PeerAddr => $options{'remoteip'}, 
            PeerPort => $options{'remoteport'}, 
            Proto => 'tcp'
            );
    if (!$remote) {
        print "Could not connect!\n";
        remove_socket($connection);
        return;
    }

    nonblock($remote);
    $select->add($remote);
    $sockets{$remote}{'type'} = 'server';

    $sockets{$connection}{'server'} = $remote;
    $sockets{$remote}{'client'} = $connection;
}

# deal with the input, based on connection type
sub handle {
    my ($connection) = @_;
    if ($sockets{$connection}{'type'} eq 'client') {
        handle_client($connection);
    } elsif ($sockets{$connection}{'type'} eq 'server') {
        handle_server($connection);
    } else {
        die "ERR, handling an unknown type: $sockets{$connection}{'type'}!\n";
    }
}

# strip any data from the client that we don't want passed to the server, then pass it
sub handle_client {
    my ($c) = @_;
    foreach my $req (@{ $ready{$c} }) {
        my $skip = 0;
        foreach my $re (@{$options{'strip_from_client'}}) {
            print "SKIP $re\n" if ($options{'debug'});
            $skip = 1 if $req =~ /$re/;
        }
        next if $skip;
        my $server = $sockets{$c}{'server'};
        print "PASSING TO $server: $req\n" if ($options{'debug'});
        $outbuffer{$server} .= $req;
    }
    delete $ready{$c};
}

# strip any data from the server that we don't want passed to the client, then pass it
sub handle_server {
    my ($s) = @_;
    foreach my $req (@{ $ready{$s} }) {
        my $skip = 0;
        foreach my $re (@{$options{'strip_from_server'}}) {
            print "SKIP $re\n" if ($options{'debug'});
            $skip = 1 if $req =~ /$re/;
        }
        next if $skip;
        my $client = $sockets{$s}{'client'};
        print "PASSING TO $client: $req\n" if ($options{'debug'});
        $outbuffer{$client} .= $req;
    }
    delete $ready{$s};
}

# nonblock($socket) puts socket into nonblocking mode
sub nonblock {
    my ($socket) = @_;
    my $flags;

    $flags = fcntl($socket, F_GETFL, 0)
      or die "Can't get flags for socket: $!\n";
    fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
      or die "Can't make socket nonblocking: $!\n";
}
