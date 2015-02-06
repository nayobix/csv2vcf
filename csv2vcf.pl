#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use File::Basename;
use Data::Dumper;
use vars qw(%options);

my $scriptname = basename($0);
my $DEBUG = 0;

my %options = (
    d => ";",	# default delimiter
);

getopts('d:i:o:', \%options);

sub usage 
{
      print "\nUsage: $scriptname [-d ;] -i input.csv -o output.egroupware.vcf\n\n";
}

if ( !defined $options{i} or !defined $options{o})
{
      usage();
      exit 127;
}

sub main
{
    my ($header, $i);
    my @headerfields;
    my @all; #All values from exported CSV
    my $output = "$options{o}";
    my $input = "$options{i}";
    my $delim = "$options{d}";

    open(FH_OUTPUT, '>', $output) or die "Could not open file $output $!";
    open(FH_INPUT, '<', $input) or die "Could not open file $input $!";

#Exported Adressbook header from Egroupware 1.8 in CSV format
#Contact ID;Type;Addressbook;private;Category;prefix;first name;middle name;last name;suffix;full name;own sorting;birthday;Company;Department;Title;Role;Assistent;Room;street (business);address line 2 (business);city (business);state (business);zip code (business);country (business);label;street (private);address line 2 (private);city (private);state (private);zip code (private);country (private);work phone;mobile phone;fax (business);assistent phone;car phone;pager;home phone;fax (private);mobile phone (private);other phone;preferred phone;email (business);email (private);url (business);url (private);Freebusy URI;Calendar URI;note;time zone;geo;public key;created;created by;last modified;last modified by;Account ID;Last date;Next date

    $header = <FH_INPUT>;
    $header =~ s/\015?\012//; #Remove all special symbols ^M and so on
    chomp $header;

    @headerfields = split /$delim/, $header;

    while (<FH_INPUT>) {
        my $record = {};
        s/\015?\012//; #Remove all special symbols ^M and so on
        chomp;
        my (@values) = split /$delim/;

        for ($i=0; $i<=$#headerfields; ++$i) {
            $record->{$headerfields[$i]} =  $values[$i];
        }

        push @all, $record;

    }

    close(FH_INPUT);

    print Dumper(@all) if $DEBUG;

    foreach my $r (@all) {
        #print "$_ => ${$r}{$_}\n";
        my $key = $_;
        my $EMAIL = ${$r}{"email (business)"};
        my $N = ${$r}{"last name"} . ";" . ${$r}{"first name"} . ";" . ${$r}{"middle name"} . ";" . ${$r}{"prefix"} . ";" . ${$r}{"suffix"};
        my $FN = ${$r}{"prefix"} . " " . ${$r}{"first name"} . " " . ${$r}{"middle name"} . " " . ${$r}{"last name"} . " " . ${$r}{"suffix"};
        my $PHONE_CELL_WORK = ${$r}{"mobile phone"};
        my $PHONE_HOME = ${$r}{"home phone"};
        my $PHONE_CAR = ${$r}{"car phone"};
        my $PHONE_OTHER = ${$r}{"other phone"};
        my $PHONE_VOICE_WORK = ${$r}{"work phone"};

        print FH_OUTPUT "BEGIN:VCARD\n";
        print FH_OUTPUT "VERSION:3.0\n";
        print FH_OUTPUT "PRODID:-//EGroupware//NONSGML EGroupware Addressbook 14.1//EN\n";
        print FH_OUTPUT "CLASS:PUBLIC\n";
    
        print FH_OUTPUT "EMAIL;TYPE=WORK:$EMAIL\n";
        print FH_OUTPUT "N:$N\n";
        print FH_OUTPUT "FN:$FN\n";
        print FH_OUTPUT "TEL;TYPE=CELL,WORK:$PHONE_CELL_WORK\n";
        print FH_OUTPUT "TEL;TYPE=HOME:$PHONE_HOME\n";
        print FH_OUTPUT "TEL;TYPE=CAR:$PHONE_CAR\n";
        print FH_OUTPUT "TEL;TYPE=OTHER:$PHONE_OTHER\n";
        print FH_OUTPUT "TEL;TYPE=VOICE,WORK:$PHONE_VOICE_WORK\n";

        print FH_OUTPUT "END:VCARD\n";
    }

    close(FH_OUTPUT);
}

&main;
