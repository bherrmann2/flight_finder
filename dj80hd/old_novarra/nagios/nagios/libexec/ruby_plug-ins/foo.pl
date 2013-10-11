@files = `dir vision9_*`;
foreach (@files) {
  print ":::$_\n";
}
