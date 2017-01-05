#!/usr/bin/perl -w
#
# Multi-language sentence splitter.
#
# Derived from the moses-smt (Moses Statistical Machine Translation)
# sentence splitter; modified slightly for our needs.
#
# moses-smt and this file are licensed under the GNU Lesser General
# Public License version 2.1 or, at your option, any later version.
#
# Based on a preprocessor written by Philipp Koehn.

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use warnings;
use FindBin qw($RealBin);
use strict;

my $mydir = "$RealBin/nonbreaking_prefixes";

my %NONBREAKING_PREFIX = ();
my $language = "en";
my $QUIET = 0;
my $HELP = 0;

while (@ARGV) {
	$_ = shift;
	/^-l$/ && ($language = shift, next);
	/^-q$/ && ($QUIET = 1, next);
	/^-h$/ && ($HELP = 1, next);
	/^-b$/ && ($|++, next); # no output buffering
}

if ($HELP) {
	print "Usage ./split-sentences.pl (-l [en|de|...]) [-q] [-b] < textfile > splitfile\n";
	print "-q: quiet mode\n";
	print "-b: no output buffering (for use in bidirectional pipes)\n";
	exit;
}
if (!$QUIET) {
	print STDERR "Sentence Splitter v3\n";
	print STDERR "Language: $language\n";
}

my $prefixfile = "$mydir/nonbreaking_prefix.$language";

#default back to English if we don't have a language-specific prefix file
if (!(-e $prefixfile)) {
	$prefixfile = "$mydir/nonbreaking_prefix.en";
	print STDERR "WARNING: No known abbreviations for language '$language', attempting fall-back to English version...\n";
	die ("ERROR: No abbreviations files found in $mydir\n") unless (-e $prefixfile);
}

if (-e "$prefixfile") {
	open(PREFIX, "<:utf8", "$prefixfile") or die "Cannot open: $!";
	while (<PREFIX>) {
		my $item = $_;
		chomp($item);
		if (($item) && (substr($item,0,1) ne "#")) {
			if ($item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/) {
				$NONBREAKING_PREFIX{$1} = 2;
			} else {
				$NONBREAKING_PREFIX{$item} = 1;
			}
		}
	}
	close(PREFIX);
}

## Loop over text, add lines together until we get a blank line or a <p>
my $text = "";
while (<STDIN>) {
	chop;
	if (/^<.+>$/ || /^\s*$/) {
		#time to process this block, we've hit a blank or <p>
		&do_it_for($text,$_);
		print "<P>\n" if (/^\s*$/ && $text); ##if we have text followed by <P>
		$text = "";
	}
	else {
		#append the text, with a space
		$text .= $_. " ";
	}
}
# Do the leftover text.
&do_it_for($text,"") if $text;


sub do_it_for {
	my($text,$markup) = @_;
	print &preprocess($text) if $text;
	print "$markup\n" if ($markup =~ /^<.+>$/);
	#chop($text);
}

sub preprocess {
	# This is one paragraph.
	my($text) = @_;

	# Clean up spaces at head and tail of each line, as well as
	# any double-spacing.
	$text =~ s/ +/ /g;
	$text =~ s/\n /\n/g;
	$text =~ s/ \n/\n/g;
	$text =~ s/^ //g;
	$text =~ s/ $//g;

	##### Add sentence breaks as needed #####

	# Non-period end of sentence markers (?!) followed by sentence starters.
	$text =~ s/([?!]) +([\'\"\(\[\¿\¡\p{IsPi}]*[\p{IsUpper}])/$1\n$2/g;

	# Multi-dots followed by sentence starters.
	$text =~ s/(\.[\.]+) +([\'\"\(\[\¿\¡\p{IsPi}]*[\p{IsUpper}])/$1\n$2/g;

	# Add breaks for sentences that end with some sort of punctuation
	# inside a quote or parenthetical and are followed by a possible
	# sentence starter punctuation and upper case.
	$text =~ s/([?!\.][\ ]*[\'\"\)\]\p{IsPf}]+) +([\'\"\(\[\¿\¡\p{IsPi}]*[\ ]*[\p{IsUpper}])/$1\n$2/g;

	# Add breaks for sentences that end with some sort of punctuation,
	# and are followed by a sentence starter punctuation and upper case.
	$text =~ s/([?!\.]) +([\'\"\(\[\¿\¡\p{IsPi}]+[\ ]*[\p{IsUpper}])/$1\n$2/g;

	# special punctuation cases are covered. Check all remaining periods.
	my $word;
	my $i;
	my @words = split(/ /,$text);
	$text = "";
	for ($i=0;$i<(scalar(@words)-1);$i++) {
		if ($words[$i] =~ /([\p{IsAlnum}\.\-]*)([\'\"\)\]\%\p{IsPf}]*)(\.+)$/) {
			#check if $1 is a known honorific and $2 is empty, never break
			my $prefix = $1;
			my $starting_punct = $2;
			if($prefix && $NONBREAKING_PREFIX{$prefix} && $NONBREAKING_PREFIX{$prefix} == 1 && !$starting_punct) {
				#not breaking;
			} elsif ($words[$i] =~ /(\.)[\p{IsUpper}\-]+(\.+)$/) {
				#not breaking - upper case acronym
			} elsif($words[$i+1] =~ /^([ ]*[\'\"\(\[\¿\¡\p{IsPi}]*[ ]*[\p{IsUpper}0-9])/) {
				# The next word has a bunch of initial quotes, maybe a
				# space, then either upper case or a number
				$words[$i] = $words[$i]."\n" unless ($prefix && $NONBREAKING_PREFIX{$prefix} && $NONBREAKING_PREFIX{$prefix} == 2 && !$starting_punct && ($words[$i+1] =~ /^[0-9]+/));
				#we always add a return for these unless we have a numeric non-breaker and a number start
			}
		}
		$text = $text.$words[$i]." ";
	}

	# We stopped one token from the end to allow for easy look-ahead. Append it now.
	$text = $text.$words[$i];

	# Clean up spaces at head and tail of each line as well as any double-spacing
	$text =~ s/ +/ /g;
	$text =~ s/\n /\n/g;
	$text =~ s/ \n/\n/g;
	$text =~ s/^ //g;
	$text =~ s/ $//g;

	# Add trailing break.
	$text .= "\n" unless $text =~ /\n$/;

	return $text;
}
