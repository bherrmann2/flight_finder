#!/usr/bin/perl 
use CGI;
$q = new CGI;
$ALLTXT = "mixwit.txt";
$CONTENT_TYPE = "Content-type: text/html\n\n";
$VERSION = 1.1;
#

print $CONTENT_TYPE;
print "<html><body>\n<h1><a href=http://www.mixwit.com>mixwit.com</a> music search version $VERSION (as of 4/4/2008)</h1>\n";
@lines = (); #hacky global for performance.
@matches = (); #hacky global for performance.

$terms = $q->param("terms");
$search_made = ($terms && ($q->param("action") eq "Search"));

if ($search_made)
{
  if (open(F,$ALLTXT))
  {
    @lines = (<F>); 
  }
  else
  {
    print "<h3>ERROR! COULD NOT OPEN DATA FILE </h3>"; exit;
  }
  #Check valid terms.
  if (&valid_terms($terms))
  {
    @matches = &get_matches($terms);
       
  }
  else
  {
    print "<h3><font color=red>The following search terms you entered were not valid.  They must be alphanumeric words seperated by spaces: '" . $terms . "'</font></h3>";
  }
}
else
{
   
	#print "GOT INVALID PARAMETERS!";
}

$form1 = "<form>Search For: <input name=terms><input name=action type=submit value='Search'>" . 
"<br><i><small><li>Search terms must be alpha numeric terms seperated by spaces e.g. 'Spears Toxic Remix'<li>If you use the mixwit.com site you will want <a href=www.mozilla.com/firefox/ >firefox</a> with the <a href=https://addons.mozilla.org/en-US/firefox/addon/748>GreaseMonkey</a> addon, and <a href=http://userscripts.org/scripts/show/24637>Nemik's Killer mixwit.com GreaseMonkey script</a><li>If you cant find it here, try <a href=http://www.beemp3.com>beemp3.com</a> or <a href=http://www.seeqpod.com>seeqpod.com</a><li>questions, comments, bug reports, etc. please email <a href=mailto:dj80hd\@scissorsoft.com>dj80hd\@scissorsoft.com</a><br></small></i></form>\n";

$form2 = "";
$num_matches = $#matches + 1;
if ($search_made)
{
  $form2 = $form2 . "NUMBER OF MATCHES : " . $num_matches. "<br>\n";
}
if ($num_matches > 0 && $search_made)
{
  $form2 = $form2 . "\n<br>Note:Some of the source directory links may not work due to configuration beyond my control.<br>" . &get_match_content(@matches) ;
}
else
{
}
print $form1, "<hr>", $form2;

sub valid_terms
{
  my $terms = shift;
  return ($terms =~ /^[ \w]+$/);
}

sub get_match_content
{
  my $out = "";
  my @matches = @_;
  foreach (@matches)
  {
    # e.g. 
    # http://www.thebejeweledgreenbottle.com/OPP/The%20Police%20-%20Regatta%20De%20Bla nc.mp3 [The Police - Regatta De Blanc] 00b727e5ff1f766459a5ad0e10f31a00
    if (/^([ \S]+) \[(.+)\] (\S{32,32})/i)
    {
      #e.g. 
      $last_slash_index = rindex($1,'/');

      # The%20Police%20-%20Regatta%20De%20Bla nc.mp3
      $filename_part = substr($1,$last_slash_index);
      # http://www.thebejeweledgreenbottle.com/OPP/
      $url_for_containing_dir = substr($1,0,$last_slash_index + 1);
      
      #@url_parts = split(/\//,$1);
      #$filename_part = $url_parts[$#url_parts];
      $out = $out . "<a href=\"$1\">$2 $filename_part</a><a target=_blank href=http://www.mixwit.com/widgets/" . $3 ."> <font color=green>source mixtape</font></a> <a target=_blank href=" . $url_for_containing_dir . "><font color=red>source directory</font></a><br>\n";
    }
    else
    {
      $out = $out . "<font color=red>INVALID: $_</font><br/>\n";
    }
  }
  return $out;
}


sub get_matches
{
  my $terms = shift;
  my @words = split(' ',$terms);
  #print "WORDS ARE " . join('---',@words);
  my @matches = ();
  foreach $line (@lines)
  {
    #Dont search the host, etc.
    @parts = split(/\//,$line);
    $part2grep = $parts[$#parts];

    $ok = 1;
    foreach $word (@words)
    {
      $ok = $ok && ($part2grep =~ /$word/i);
      next if !$ok;
    }#foreach word
    push (@matches,$line) unless !$ok;
  }#foreach $line
  return @matches;
}#get_matches
