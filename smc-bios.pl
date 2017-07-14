#!/usr/bin/env perl

use strict;
use warnings;
use LWP::UserAgent;

my $ua       = LWP::UserAgent->new;
my $url      = 'https://www.supermicro.com/ResourceApps/BIOS_IPMI_Intel.html';
my $response = $ua->get($url);
$response->is_success or die "$url: $response->status_line";

my %version;
my @SKU;

for my $tr ( $response->decoded_content =~ m{<tr[^>]+>(.*?)</tr>}gs ) {
    my @td = $tr =~ m{<td[^>]+>(.*?)</td>}g or next;
    @td == 8 or next;
    $td[2] =~ s/.*>([^<]+)<.*/$1/ or die $tr;
    for my $SKU ( $td[0] =~ m/>([^<]+)</g ) {
        $SKU =~ /^X[91]/ or next;
        exists $version{$SKU} or push @SKU, $SKU;
        if ( $td[6] =~ /bios/i ) {
            $version{$SKU}{BIOS} = $td[2];
        }
        elsif ( $td[6] =~ /ipmi/i ) {
            $version{$SKU}{IPMI} = $td[2];
        }
    }
}

open my $fh, '>', 'version.tsv' or die $!;
print $fh "SKU\tBIOS\tIPMI Firmware\n";
for my $SKU (@SKU) {
    printf $fh "%s\t%s\t%s\n", $SKU, $version{$SKU}{BIOS}, $version{$SKU}{IPMI} // "";
}
