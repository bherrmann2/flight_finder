#remove whitespace from the start and end of the string
sub hexstr {
    my @list = unpack( 'H32', $_[0] );
    my $result = sprintf( "%-32s", $list[0] );
    my $expanded;

    while ( $result =~ /(..)/g ) {
        $expanded .= $1 . ' ';
    }
    return $expanded;
}
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
#Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
#Right trim function to remove trailing whitespace
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub uniq
{
  my @a = @_;
  my %hashTemp = map { $_ => 1 } @a;
  return sort keys %hashTemp;
}


sub hexDumpStringToBinaryFile #($hexContent, $filename) returns size of file
{
	my $hexContent = shift;
	my $filename = shift;
	open(OUT,">" . $filename) || die "Could not open file " . $filename;
	binmode(OUT);
	for ($i=0;$i<length($hexContent);$i=$i+2)
	{
	$hexDigits = substr($hexContent,$i,2);
	$byte = pack ('H2', $hexDigits);
	print OUT $byte;
	}
	close(OUT);
	return length($hexContent);

}

#Returns the contents of a file (including whitespace)
sub file2string #($filename)
{
  my $filename = shift;
  open(F,$filename) || die "Could not open $filename";
  my $content = join('',(<F>));
  close F;
  return $content;
}

#returns the contents of a file as an array of lines (newlines are excluded)
sub file2lines #($filename)
{
  my $filename = shift;
  my $content = file2string($filename);
  return split(/\n/,$content);
}

#writes a file with the contents of a string
sub string2file #($filename, $string);
{
  my ($filename,$string) = @_;
  open(F,">$filename") || die "Cannot open $filename";
  print F $string;
  close F;
}

#Writes an array of lines to a file (LINES SHOULD NOT CONTAIN NEWLINES)
sub lines2file #($filename, @lines)
{
  my ($filename,@lines) = @_;
  string2file($filename,join("\n",@lines));
}

1;
