use strict;
use List::Util qw(min max);

sub println { print "@_"."\n" }

my $N = shift @ARGV; # First command line arg, represents the N in N-gram
my $M = shift @ARGV; # Second command line arg, number of sentences to generate at end
my @files = (); # All remaining command line args, list of files to read from
my @ngrams = (); # Array of hashes, [1] contains a hash of 1-grams to their frequencies, [2] is 2-grams to their frequencies, etc.

for(my $i = 0; $i < $N; $i++){ # Initialize a new hash for all values 1-N
    my %hash;
    $ngrams[$i] = \%hash;
}

foreach my $file (@ARGV){ # For every file name given on the command line
    if (-f $file){ # If file exists push it onto @files
        push @files, $file;
    } else { # Else ignore it and keep going
        warn "WARN: File $file does not exist. Ignoring it and continuing";
    }
}

foreach my $file (@files){
    println "Processing file $file...";
    if(open(my $fh, "<:encoding(UTF-8)", $file)){ # Attempt to open file
        my $text = do { local $/; <$fh> }; # Read in the entire file as a string
        chomp $text;
        $text = lc $text; # Convert to lowercase
        $text =~ s/[!\?\.]/ <end> <start> /g; # Replace !, ?, and . with sentence separation
        # println $text;

        my @tokens = split(/[\s\n]+/, $text);
        
        for(my $i = 0; $i < 0+@tokens; $i++){
            # For each token, go from 1-N, and for each value assemble the corresponding
            # N-gram from the current (i) token and the N-1 tokens before it
            for(my $n = 1; $n <= $N; $n++){
                if($i-$n+1 < 0) { next; } # If not enough tokens before this one to make an $n -gram, skip this $n
                my $gram = "";
                for(my $n2 = 0; $n2 < $n; $n2++){
                    $gram = $gram eq "" ?
                        $tokens[$i-$n2] :
                        $tokens[$i-$n2]." ".$gram;
                }
                $ngrams[$n]{$gram}++;
            }
        }

        use Data::Dumper;
        print Dumper(@ngrams[1]);

        close $fh;
    } else { # If unable to open file, ignore it and keep going
        warn "WARN: Error opening file $file. Ignoring it and continuing";
    }
}