use strict;
use List::Util qw(min max);

sub println { print "@_"."\n" }

my $N = shift @ARGV; # First command line arg, represents the N in N-gram
my $M = shift @ARGV; # Second command line arg, number of sentences to generate at end
my @files = (); # All remaining command line args, list of files to read from
my @ngrams = (); # Array of hashes, [1] contains a hash of 1-grams to their frequencies, [2] is 2-grams to their frequencies, etc.

for(my $i = 0; $i < $N; $i++){
    my %hash;
    $ngrams[$i] = \%hash;
}

foreach my $file (@ARGV){
    if (-f $file){
        push @files, $file;
    } else {
        warn "WARN: File $file does not exist. Ignoring it and continuing";
    }
}

foreach my $file (@files){
    println "Processing file $file...";
    if(open(my $fh, "<:encoding(UTF-8)", $file)){
        my $text = do { local $/; <$fh> }; # Read in the entire file as a string
        chomp $text;
        my @tokens = split(/[\s\n]+/, $text);
        
        for(my $i = 0; $i < 0+@tokens; $i++){ # For each token
            # Go from 1-N, and for each value assemble the corresponding
            # N-gram from the current (i) token and the N-1 tokens before it
            for(my $n = 1; $n <= $N; $n++){
                if($i-$n+1 < 0) { next; } # If not enough tokens before this one to make an $n -gram, skip this $n
                my $gram = "";
                for(my $n2 = 0; $n2 < $n; $n2++){
                    $gram = $tokens[$i-$n2]." ".$gram;
                }
                $ngrams[$n]{$gram}++;
            }
        }

        use Data::Dumper;
        print Dumper(@ngrams);

        close $fh;
    } else {
        warn "WARN: Error opening file $file. Ignoring it and continuing";
    }
}