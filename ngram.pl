use strict;
use Data::Dumper;
use List::Util qw(min max);
use List::MoreUtils qw(uniq);

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
        warn "WARN: File '$file' does not exist. Ignoring it and continuing";
    }
}

# Process the files and build the N-gram models
foreach my $file (@files){
    println "Processing file '$file'...";
    if(open(my $fh, "<:encoding(UTF-8)", $file)){ # Attempt to open file
        my $text = do { local $/; <$fh> }; # Read in the entire file as a string
        chomp $text;
        $text = lc $text; # Convert to lowercase
        $text =~ s/^/<start> /g; # Insert <start> tag at beginning of first sentence
        $text =~ s/(?<!(mr|ms|dr|sr))[\!\?\.](?!$)/ <end><split><start> /g; # Replace all !, ?, and . with separators unless it's the end of the file
        $text =~ s/[\!\?\.](?=$)/ <end>/g; # Replace the one at the end of the file
        $text =~ s/([\(\)\$,'`"\x{2019}\x{201c}\x{201d}%&:;])/ $1 /g; # Separate punctuation characters into their own tokens
        
        my @sentences = split(/<split>/, $text);
        
        foreach my $sentence (@sentences){
            # $n runs for two loops, taking the values $N-1 and $N,
            # so you're assembling all $N-grams and all ($N-1)-grams
            for(my $n = $N-1; $n <= $N; $n++){
                # Duplicate <start> and <end> tags based on $n
                my $sentenceCopy = $sentence =~ s/<start>/" <start> "x$n/egr;
                $sentenceCopy =~ s/<end>/" <end> "x$n/eg;
                $sentenceCopy =~ s/^\s+|\s+$//g; # Trim whitespace

                # Split sentence into tokens
                my @tokens = split(/[\s\n]+/, $sentenceCopy);
                if(0+@tokens < $N-2){ next; } # If not enough tokens in this sentence (minus the <start> and <end>) then skip it

                # For each token in the sentence, assemble the corresponding
                # $n-gram from it and the $n-1 tokens before it, respectively
                # $n will take the values of $N and $N-1
                for(my $i = 0; $i < 0+@tokens; $i++){
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

        # print Dumper(@ngrams[$N-1]);

        close $fh;
    } else { # If unable to open file, ignore it and keep going
        warn "WARN: Error opening file $file. Ignoring it and continuing";
    }
}


my %P; # A hash of hashes s.t. $P{p}{q} = P(p|q) = the probability that the next word is p given we've just seen q

# Populate P with possible tokens (1-grams)
foreach my $ngram (keys %ngrams[$N]){
    my $temp = $ngram =~ s/.*\s+(.+)$/$1/gr;
    my %hash;
    $P{$temp} = \%hash;
}

# Populate all keys p in P{p} with possible ($N-1)-grams and their probability
foreach my $p (keys %P){
    foreach my $n1gram (keys %ngrams[$N-1]){
        $P{$p}{$n1gram} = $ngrams[$N]{$n1gram." ".$p} / $ngrams[$N-1]{$n1gram};
        # print $p." ".$n1gram."       ".$ngrams[$N]{$n1gram." ".$p}." / ".$ngrams[$N-1]{$n1gram}."           $n1gram";
        # println $P{$p}{$n1gram};
    }
}
print Dumper(%P{"<start>"});