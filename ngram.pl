use strict;
use Data::Dumper;
use List::Util qw(min max);

sub println { print "@_"."\n" }

if(0+@ARGV < 3){
    die "At least 3 arguments required.";
}

my $N = shift @ARGV; # First command line arg, represents the N in N-gram
my $M = shift @ARGV; # Second command line arg, number of sentences to generate at end
my @files = (); # All remaining command line args, list of files to read from
my @ngrams = (); # Array of hashes, [1] contains a hash of 1-grams to their frequencies, [2] is 2-grams to their frequencies, etc.

if($N < 1) { die "N must be greater than 0 (you provided $N)"; }
if($M < 0) { die "M must be nonnegative (you provided $M)"; }

# Initialize a new hash for values N and N-1
for(my $i = $N-1; $i <= $N; $i++){
    my %hash;
    $ngrams[$i] = \%hash;
}

# Validate filenames
foreach my $file (@ARGV){
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
        $text =~ s/[!\?\.]/ <end><split><start> /g; # Replace !, ?, and . with sentence separation
        $text =~ s/([\(\)\$,'`"\x{2019}\x{201c}\x{201d}%&:;])/ $1 /g; # Separate punctuation characters into their own tokens
        
        my @sentences = split(/<split>/, $text);

        foreach my $sentence (@sentences){
            # For each sentence, go through the tokens in it
            my @tokens = split(/[\s\n]+/, $sentence);
            if(0+@tokens < $N-2){ next; } # If not enough tokens in this sentence (minus the <start> and <end>) then skip it
            
            for(my $i = 0; $i < 0+@tokens; $i++){
                # For each token, assemble the corresponding N-gram and (N-1)-gram
                # from it and the N-1/N-2 tokens before it, respectively
                for(my $n = $N-1; $n <= $N; $n++){
                    if($i-$n+1 < 0) { next; } # If not enough tokens before this one to make an $n-gram, skip this $n
                    my $gram = "";
                    for(my $n2 = 0; $n2 < $n; $n2++){
                        $gram = $gram eq "" ?
                            $tokens[$i-$n2] :
                            $tokens[$i-$n2]." ".$gram;
                    }
                    $ngrams[$n]{$gram}++;
                }
            }
        }
        
        print Dumper(@ngrams[2]);

        close $fh;
    } else { # If unable to open file, ignore it and keep going
        warn "WARN: Error opening file $file. Ignoring it and continuing";
    }
}