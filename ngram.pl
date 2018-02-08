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
        println "\tFormatting text...";
        $text = lc $text; # Convert to lowercase
        $text =~ s/^/<start> /g; # Insert <start> tag at beginning of first sentence
        $text =~ s/(?<!(mr|ms|dr|sr))[\!\?\.](?!$)/ <end><split><start> /g; # Replace all !, ?, and . with separators unless it's the end of the file
        $text =~ s/[\!\?\.](?=$)/ <end>/g; # Replace the one at the end of the file
        $text =~ s/([\(\)\$,'`"\x{2019}\x{201c}\x{201d}%&:;])/ $1 /g; # Separate punctuation characters into their own tokens
        
        my @sentences = split(/<split>/, $text);
        
        println "\tBuilding N-grams...";
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
        println "\tClosing '$file'";
        close $fh;
    } else { # If unable to open file, ignore it and keep going
        warn "WARN: Error opening file $file. Ignoring it and continuing";
    }
}

println "Calculating probabilities...";
my %P; # A hash of hashes s.t. $P{a}{b} = P(b|a) = the probability that the next word is b given we've just seen a
my @tokens; # An array of all tokens (i.e. 1-grams)

# Populate @tokens with all possible tokens (last words of $N-grams)
foreach my $ngram (keys %ngrams[$N]){
    my $temp = $ngram =~ s/.*\s+(.+)$/$1/gr; # Get last word
    push @tokens, $temp;
}

# Populate P with all of the ($N-1)-grams
foreach my $n1gram (keys %ngrams[$N-1]){
    my %hash;
    $P{$n1gram} = \%hash;
}

# Populate all keys a in P{a} with all possible tokens and their probability of occurring after a
my $totalToCalculate = 0+(keys %P);
my $completedCalculations = 0;
my $PROGRESS_PRINT_INCR = 1.0; # Constant for how often to print the progress update
my $lastProgressPrinted = 0.0; # Prints progress update when the progress gets past this by at least $PROGRESS_PRINT_INCR
println "\tThis part takes a while, I'll print out the progress as I go so you know I'm not frozen";
foreach my $a (keys %P){
    foreach my $token (@tokens){
        if($a =~ /^((<start>)|\s)+$/ && $token eq "<start>") { next; }
        my $freq = $ngrams[$N]{$a." ".$token} / $ngrams[$N-1]{$a};
        if($freq > 0){
            $P{$a}{$token} = $freq;
        }
    }
    # This part takes a while, so here's a little bit of code that will print its progress as it goes
    $completedCalculations++;
    my $progress = ($completedCalculations/$totalToCalculate) * 100;
    if($progress > $lastProgressPrinted + $PROGRESS_PRINT_INCR){
        $lastProgressPrinted += $PROGRESS_PRINT_INCR;
        println "\t$progress%...";
    }
}

println "Generating sentences...";
# Generate $M sentences using the probabilities in %P
for(my $m = 1; $m <= $M; $m++){
    # Build beginning of sentence with right amount of <starts> ($N-1 of them)
    my $sentence = "";
    for(my $n = 0; $n < $N-1; $n++){
        $sentence .= "<start>";
        if($n != $N-1){ $sentence .= " "; }
    }
    my $temp = 0;
    while($sentence =~ /(?<!<end>)$/){
        my $random = rand 1;
        # println "RANDOM: ".$random;
        my $counter = 0.0;

        my @temp = split(/\s+/, $sentence);
        my @lastNWordsTemp;
        for(my $i = 1; $i < $N; $i++){
            unshift @lastNWordsTemp, pop @temp;
        }
        my $lastNWords = join(" ", @lastNWordsTemp);
        # println "SENTENCE: $sentence LASTN: $lastNWords";
        
        foreach my $token (keys %{$P{$lastNWords}}){
            # println $token." $P{$lastNWords}{$token}";
            if($P{$lastNWords}{$token} == 0) { next; }
            $counter += $P{$lastNWords}{$token};
            # println "COUNTER: ".$counter;
            if($counter > $random){
                $sentence .= " ".$token;
                # println "SENTENCE: ".$sentence;
                last;
            }
        }
        $temp++;
    }

    # Format sentence for printing
    $sentence =~ s/^\s+|\s+$//g; # Trim whitespace
    $sentence =~ s/<start>\s+//g; # Remove <start> tags
    $sentence =~ s/\s+<end>/\./; # Replace <end> tag with a period
    $sentence =~ s/\s+(['`])\s+/$1/g; # Remove whitespace around mid-word punctuation marks
    $sentence =~ s/\s+([,;:\x{2019}\x{201d}])/$1/g; # Remove whitespace before post-word punctuation marks
    $sentence =~ s/([\x{2018}\x{201c}])\s+/$1/g; # Remove whitespace after pre-word punctuation marks
    
    # Finally, print the sentence
    println "SENTENCE $m: ".$sentence;
}