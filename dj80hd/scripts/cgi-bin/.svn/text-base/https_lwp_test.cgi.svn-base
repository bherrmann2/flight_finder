#!/usr/bin/perl 
use strict;
use warnings;


use LWP::UserAgent;

print "Content-Type: text/html\n\n";

my $url = 'https://www.helsinki.fi/';

my $ua = LWP::UserAgent->new;
my $response = $ua->get( $url );

$response->is_success or
    die "Failed to GET '$url': ", $response->status_line;

print $response->as_string;


