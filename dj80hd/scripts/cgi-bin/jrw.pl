sub command2String #($cmd)
{
	my $cmd = shift;
	my $out = "";
	#ajkdfa;
	open(R, "$cmd |") || die "Could not run program $cmd";
	while (<R>)
	{
		$out .= $_;
	}
	close (R);
	return $out;
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
	return length($hexContent)/2;

}

sub randomFileName #($prefixString, $fileExtention)
{
	my $prefixString = shift;
	my $fileExtention = shift;
	return  $prefixString.  time() . "-" . rand(time()) . "." . $fileExtention;
}
1;
