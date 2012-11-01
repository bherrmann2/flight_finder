#! /usr/bin/perl -w
#! perl -w
$REAL_EMAIL = 1;
#
# 04/07/2005 - resendInvitesToDeadbeats feature, Admin Survey Form
#
# TODO
#
# - Error Cases
#   * No choices for SINGLE_SELECT or MULTIPLE_SELECT
# - test Mail part
# - good emails, maximum number of emails
# - Support errors on mail
# - create directory if it doesn't exist
# - results show number of respondants
# - filter all input for harmful characters
# - add version number to everything for backward compat.
# - Anonymous surveys (people invite themselves)
# - autocreate of surveydata directory on first startup
# - clean up create survey form
# - clean up vote form
# - create survey error checking
#
# FEATURES
# - BIG TEXT and NUMERIC options.
# - change votes
# - graphic display of results
# - save email lists
#
# BUGS
# - Leave first question blank when creating a survey
# - Text Area For Comments
#
#
#
use CGI;
#----------------------- TO BE CONFIGURED ------------------------------
#$MY_URL = "http://www.scissorsoft.com/cgi-bin/survey.pl";
$ADMIN_PASS = "kerry4";
$DEBUG = 0;
$BAR_IMAGE_FILE = "/images/bar.jpg";
$FROM_EMAIL = "surveymaster\@scissorsoft.com";
$SENDMAIL = '/usr/lib/sendmail -f webform@wimkp.org';
#-----------------------------------------------------------------------
$q = new CGI;
$MY_URL = "http://" . $ENV{'HTTP_HOST'} . $ENV{'SCRIPT_NAME'} unless ($MY_URL);
if ($REAL_EMAIL && ($ENV{'HTTP_HOST'} =~ m/127\.0\.0\.1/))
{
	$REAL_EMAIL = 0; #no real email for localhost
}
$action = $q->param('action');
$surveyName = $q->param('name');
$code = $q->param('code');
@FILE_LINES = ();
$MAX_QUESTIONS = 10;
$QUESTION = 2;
$QUESTIONS = [];
%INVITED_IDS = (); # hash of id 2 email 
%INVITED_EMAILS = (); # hash of email 2 id 
@RESPONDANT_IDS = (); #FIXME - find a better way
@RESPONDANT_EMAILS = (); #FIXME - find a better way
@NOSHOW_EMAILS = (); #FIXME - find a better way
$DATA_DIR = "surveydata/";
print $q->header();
print &topOfEveryPage;

if (!$action) 
{
  $action = "";
}
if ($action eq "Create Survey")
{
	if( $q->param("adminEmail"))
		{
			$FROM_EMAIL = $q->param("adminEmail");
		}
	if ($q->param("password") eq $ADMIN_PASS)
	{
  #FIXME - Must make sure name is unique
  &createSurvey($q);
  	}
	else
	{
		print("You have entered an incorrect password.");
	}
}
elsif ($action eq "Create Survey Form")
{
  &printCreateForm; 
}
elsif ($action eq "Submit Survey")
{
  &createSurvey($q);
}
elsif ($action eq "Take Survey Form")
{
  &loadData($surveyName);
  &takeSurvey($q);
}
elsif ($action eq "Admin Survey Form")
{
  &loadData($surveyName);
  &adminSurveyForm($q);
}
elsif ($action eq "Resend Invites To Deadbeats")
{
	if ($q->param("password") eq $ADMIN_PASS)
	{
  		&loadData($surveyName);
  		&resendInvitesToDeadbeats($q);
  	}
	else
	{
		print("You have entered an incorrect password.");
	}
}
elsif ($action eq "Vote")
{
  &loadData($surveyName);
  &vote;
}
elsif ($action eq "View Results")
{
  &loadData($surveyName);
  &viewResults;
}
elsif ($action eq "Test")
{
  &loadData($surveyName);
  &test;
}
elsif ($action eq "Simulate Email")
{
  &simulateEmail;
}
elsif ($action eq "Reset All")
{
	if ($q->param("password") eq $ADMIN_PASS)
	{
   if ($DEBUG) 
	 {
	 &resetAll;
	 }
  }
	else
	{
		print("You have entered an incorrect password.");
	}
}
elsif ($action ne "")
{
	print ("Unexpected action: $action");
}
else
{
	print "<OL>";
	print "<li>";
  print "<form>";
	print "<input type=submit name=action value=\"Create Survey Form\">";
	print "</form>";
	print "<li>See Results:";
  	print "<form>";
	print "<input type=hidden name=code value=\"abcdef\">";
	print "<select name=name><option>" . join ("<option>",&getAllSurveyNames) . "</select>";
	print "<input type=submit name=action value=\"View Results\">";
	print "</form>";
	print "<li>Test:";
  	print "<form>";
	print "<input type=hidden name=code value=\"abcdef\">";
	print "<select name=name><option>" . join ("<option>",&getAllSurveyNames) . "</select>";
	print "<input type=submit name=action value=\"Test\">";
	print "</form>";
  	print "<form>";
	print "<input type=hidden name=code value=\"abcdef\">";
	print "<select name=name><option>" . join ("<option>",&getAllSurveyNames) . "</select>";
	print "<input type=submit name=action value=\"Admin Survey Form\">";
	print "</form>";
	print "<li>Test:";
  	print "<form>";
	print "<input type=submit name=action value=\"Simulate Email\">";
	print "</form>";
	print "<li>";
	print "Password:<input type=password name=password>";
  	print "<form>";
	print "<input type=submit name=action value=\"Reset All\">";
	print "</form>";

	print "<hr>";
	if ($DEBUG)
	{
		print "<ul><li>" . join ("<li>",&getAllSurveyNames) . "</ul>";
		print "<hr>";
		&dumpQuery;
	}
  #&test;
	
exit;
}
sub resetAll
{
	@gonners = ();
	if (opendir D, "surveydata")
	{
		@all = readdir D;
		close D;
		foreach (@all)
		{
			if (/\.txt$/)
			{
				push (@gonners,"surveydata" . "/" . $_);
			}
		}
	}
	else
	{
		print "<h2>BAD NEWS: $!</h2>";
	}
	print "<B>DELETENG the following files: </b><br>", join ("<li>",@gonners);
	$count = unlink @gonners;
	print "<br>$count files deleted.";
}#resetAll


sub getAllSurveyNames
{
	@ret = ();
	if (opendir D, "surveydata")
	{
		@allfiles = readdir D;
		close D;
		foreach (@allfiles)
		{
			if (/-\d+\.txt$/)
			{
				s/\.txt$//g;
				push @ret, $_;
			}
		}
	}
	else
	{
		print "<h2>BAD NEWS: $!</h2>";
	}
	return @ret;
	
}
sub getLines
{
  $surveyname = shift;
  $filename = "surveydata/" . $surveyname . ".txt";
  open (F,$filename);
  @lines = (<F>);
  close F;
	return @lines;
}#getLines

sub adminSurveyForm
{
	print "<form>";
	print "<input type=hidden value='" . $surveyName . "' name=name>\n";
	print "Admin Password: <input type=password name=password><br>\n";
	print "Type any message here that you want to send to the deadbeats:<br><textarea rows=5 cols=100 name=invite>Reminder: Please vote !</textarea><br>\n";
	print "<input type=submit name=action value='Resend Invites To Deadbeats'><br>\n";
	print "</form>";
}
sub resendInvitesToDeadbeats
{
	my $q = shift;
	$password = $q->param('code');
	$invite   = $q->param('invite');
	&sendEmails("Please Take my Survey here: ",@NOSHOW_EMAILS);
}#resendInvitesToDeadbeats
sub test
{
&dumpAll;
foreach (keys (%INVITED_IDS))
{
	print "<b>$_</b>=" . &getEmail($_) . "<br>";
}
print "RESPONDANTS: " . join(",",@RESPONDANT_EMAILS);
print "<br>NOSHOWS: " . join(",",@NOSHOW_EMAILS);
}#test

sub loadData
{
	$surveyName = shift;
	@lines = &getLines($surveyName);
	&parseQuestions(@lines);
	&parseAnswers(@lines);
	&parseInvited(@lines);
	@FILE_LINES = @lines;
	foreach (@RESPONDANT_IDS)
	{
		push @RESPONDANT_EMAILS, &getEmail($_);
	}
	&initNoShowEmails();
}#loadData

sub getNoShowEmails
{
	if (@NOSHOW_EMAILS)
	{
	}
	else
	{
		&initNoShowEmails;
	}
	return @NOSHOW_EMAILS;
}
sub initNoShowEmails
{
	        @NOSHOW_EMAILS = ();
		@invitedEmails = values(%INVITED_IDS);
		foreach $invitedEmail (@invitedEmails)
		{
			if (grep(/^$invitedEmail/,@RESPONDANT_EMAILS))
			{
			}
			else
			{
				push @NOSHOW_EMAILS,$invitedEmail;
			}
		}

}

sub getAnswers
{
  my $question = shift;
  my @lines = @_;
  @answers = grep /^_ANSWER\|$question\|/,@lines;
  foreach (@answers)
  {
    chop;
    @values = split /\|/,$_;
    shift @values; #pop off _ANSWER
    shift @values; #pop off Question number
    $who = shift @values;
    print ">>>VALUES:" . join(',',@values) . "\n" unless (! $DEBUG);
  }
  return @values;
  
}#getAnswers

sub parseInvited
{
	my @lines = @_;
	my @values = ();
	foreach (@lines)
	{
		if (/^SURVEY_INVITED/)
		{
			chop;
			@values = split /\|/,$_;
			$dummy = shift @values;
			$email = shift @values;
			$id = shift @values;
			$INVITED_IDS{$id} = $email;
			$INVITED_EMAILS{$email} = $id;
		}
		elsif (/^SURVEY_ADMIN_EMAIL/)
		{
			chop;
			@values = split /\|/,$_;
			$dummy = shift @values;
			$FROM_EMAIL = shift @values;
		}	
	}
  
}#end parseInvited

#-----------------------------------------------------------------------
sub parseQuestions
#-----------------------------------------------------------------------
{
  my @lines = @_;
  my @values = ();
  foreach (@lines)
  {
    if (/^SURVEY_QUESTION/)
    {
		  chop;
      @values = split /\|/,$_;
      $dummy = shift @values;
      $index = shift @values;
      $type = shift @values;
      $text = shift @values;
      $QUESTIONS->[$index] = {};
      $hash_ref = $QUESTIONS->[$index];
      $hash_ref->{"TYPE"} = $type;
      $hash_ref->{"TEXT"} = $text;
      $hash_ref->{"INDEX"} = $index;
	$hash_ref->{"CHOICES"} = [@values];
      $hash_ref->{"ANSWERS"} = {};

	#TALLY is hashmap of choice values to an array if ids that voted 4 them
	$hash_ref->{"TALLY"} = {};
	foreach $choice (@{$hash_ref->{"CHOICES"}})
	{
		$hash_ref->{"TALLY"}->{$choice} = [] unless (! $choice) ; 
	}

			$hash_ref->{"TOTAL_VOTES"} = 0;
			print "Got Question: " . $index . " " . $type . " " . $text . " " . join(',',@{$hash_ref->{"CHOICES"}}) . "\n" unless (! $DEBUG);
    } 
  }
  
}#end parseQuestions

sub getOptionsHtmlFromArray
{
 #@rawOptions = @_;
 #my $ret = "";
 
}
sub getQuestionHtml
{
	my $ALLOW_OTHERS_ANSWERS_AS_CHOICES = 1;
  my $index = shift;
	my $hash_ref = $QUESTIONS->[$index];
	my $string = "";
	$string .= $hash_ref->{"TEXT"} . ":";

	#FIXME - This is alot of cut-and-paste
	if ($hash_ref->{"TYPE"} eq "TEXT")
	{
	  $string .= "<input name=answer-" . $index . " >";
	}
	elsif ($hash_ref->{"TYPE"} eq "SINGLE_SELECT")
	{
	  $string .= "<select name=answer-" . $index . " >";
		$string .= "<option>" . join("<option>",@{$hash_ref->{"CHOICES"}});
		$string .= "</select>";
	}
	elsif ($hash_ref->{"TYPE"} eq "MULTIPLE_SELECT")
	{
		$string .= "<select multiple name=answer-" . $index . " >";
		$string .= "<option>" . join("<option>",@{$hash_ref->{"CHOICES"}});
		$string .= "</select>";
	}
	elsif (($hash_ref->{"TYPE"} eq "SINGLE_SELECT_OR_OTHER") || 
		($hash_ref->{"TYPE"} eq "MULTIPLE_SELECT_ANDOR_OTHER"))
	{
		$hash_ref->{"TYPE"} =~ /(MULTIPLE)/;
		$string .= "<select $1 name=answer-" . $index . " >";
		if ($ALLOW_OTHERS_ANSWERS_AS_CHOICES)
		{

			$string .= "<option>" . join("<option>",&getAllPossibleChoices($index));
		}
		else
		{
			$string .= "<option>" . join("<option>",@{$hash_ref->{"CHOICES"}});
		}
		$string .= "</select>";
		$string .= "Other:<input name=answer-" . $index . "other >";
	}
	return $string;

}#getQuestionHtml

sub getAllPossibleChoices
{
	my $index = shift;
	@origchoices = @{$QUESTIONS->[$index]->{"CHOICES"}};

	foreach $line (@lines)
	{
		if ($line =~ /^SURVEY_ANSWER\|$index\|/)
		{
			@values = split /\|/,$line;
			$dummy = shift @values;
			$index = shift @values;
			$who = shift @values;
			foreach $v (@values)
			{
				$v =~ s/^\s+//g;
				$v =~ s/\s+$//g;
				push @origchoices,$v unless (! $v);
			}
		}
	}
	#uniuq-ify
	%seen=();
	@unique = grep { ! $seen{$_}++ } @origchoices;
	return @unique;
}#getAllPossibleChoices

sub parseAnswers
{
  my @lines = @_;
  my @values = ();
  foreach (@lines)
  {
    if (/^SURVEY_ANSWER/)
    {
		  chop;
      @values = split /\|/,$_;
      $dummy = shift @values;
      $index = shift @values;
      $who = shift @values;
      $who =~ s/^\s+//; $who =~ s/\s+$//;
      #choices are what is left in @values
	foreach (@values)
	{
		if (! $QUESTIONS->[$index]->{"TALLY"}->{$_})
		{

			$QUESTIONS->[$index]->{"TALLY"}->{$_} = [];
		}

		push 	@{$QUESTIONS->[$index]->{"TALLY"}->{$_}}, $who;
		$QUESTIONS->[$index]->{"TOTAL_VOTES"}++
				
	}
	push	@RESPONDANT_IDS,$who unless (grep /$who/,@RESPONDANT_IDS);

      $answer_hash_ref = $QUESTIONS->[$index]->{"ANSWERS"};
      $answer_hash_ref->{$who} = [@values];
      #print "Got Answer: " . $index . " " . $who . " " . join(',',@{$answer_hash_ref->{$who}}) . "\n";
			
     
    } 
  }
  
}#end parseAnswers

sub dumpAll
{
  $i = 0;
  print "INVITED:";
  foreach (keys (%INVITED_IDS))
  {
	  print "<br><b>" . $_ . ": </b>" . $INVITED_IDS{$_};
  }
  print "<hr>";
  print &getSurveyFileAsHtml;
  print "<hr>";
  
  foreach $question_hash_ref (@{$QUESTIONS})
  {
    if ($question_hash_ref)
    {
      print ("QUESTION $i: " . $question_hash_ref->{"TEXT"} . "  (type=" . $question_hash_ref->{"TYPE"}  . ")\n");
      foreach $key (keys (%{$question_hash_ref->{"ANSWERS"}}))
      {
         print ("  " . $key . ":" . join(";",@{$question_hash_ref->{"ANSWERS"}->{$key}}) . " \n");
      }
			foreach $choice (@{$question_hash_ref->{"CHOICES"}})
			{
			  if ($question_hash_ref->{"TALLY"}->{$choice})
				{
			    $count = @{$question_hash_ref->{"TALLY"}->{$choice}};
				}
				else
				{
				  $count = 0;
				}
			  print ("--" . $choice . ": total=" . $count . "   " . ($count * 100/ $question_hash_ref->{"TOTAL_VOTES"}) . "% " . "\n");
			}

    }
    $i++;
  }
  print "<hr>";
  &dumpQuery;
  print "<hr>" . &dumpEnv();
}
sub getQuestionLineForFile
{
  ###FIXME - make these "my" ?
  $q = shift;
	$i = shift;
	
	
  $line = "";
	$question = $q->param("question-" . $i);
	$type = $q->param("type-" . $i);
	$choices = $q->param("choices-" . $i);
  if ($q->param("question-" . $i))
  {
	  
		#comma delimted to |-delimeted
		@options = split(',',$choices);
		$choices = "";
		foreach(@options)
		{
			s/^\s+//;
			s/\s+$//;
			if ($_)
			{
				$choices .= "|$_";
			}
		}
		
		$line =  "SURVEY_QUESTION|" . $i . "|" . $type . "|" . $question  . $choices;
	}
	else
	{
	   #$line = "NO LINE $i";
	}
	return $line ;# . "<br>";
}
sub getInviteEmails
{
  $q = shift;
	my $ret = "";
	$list = $q->param("inviteList");
	$list =~ s/\s//g; #no white spaces
	@emails = split /,/ , $list;
	return @emails;
}
sub newLinesToBr
{
  my $s = shift;
	$s =~  s/\n/<br>/g;
	return $s;
}

sub idToEmail
{
	my $id = shift;
	foreach (@FILE_LINES)
	{
		if (/^SURVEY_INVITED\|(\S+)\|$id/)
		{
			return $1;
		}
	}
	return "";
}
sub nameToSurveyId
{
	my $name = shift;
	$name =~ s/\s+/_/g;
	$name =~ s/\W//g;
	$name .= "-" . time();
}
#FIXME - Handle errors


sub randomPassword
{
	@chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$pass = join("",@chars[map{rand @chars}(1 .. 8)]);
  return $pass;
}

sub takeSurvey
{
	$code = $q->param("code");
	$name = $q->param("name");
	print "<b>Welcome " . &getEmail($code) . "</b><br>";
	if (! &isInvited($code))
	{
		print "<b>You have not been invited to this survey !</b>";
		return;
	}
	if (&hasAlreadyVoted($code))
	{
		#Links to change vote, view vote or view results
		print "<b>You have already voted for this survey.</b>";
		print "<br>To view the results of this survey go here:";
		print "<a href='" . &getViewResultsUrl . "'>" . &getViewResultsUrl . "</a>";
		return;
	}
	$html = "<form method=post><ol>";
	my $i = 0;
	foreach(@{$QUESTIONS})
	{
		if ($_)
		{
		$html .= "<li>";
			$thisquestion = getQuestionHtml($_->{"INDEX"});
			$html .= $thisquestion;
			$i++;
		}	
		else
		{
		}
	}
	$html .= "</ol>";

	$html .= "<input type=submit name=action value=Vote>";
	$html .= "<input type=reset>";
	$html .= "<input type=hidden name=code value=\"$code\">";
	$html .= "<input type=hidden name=name value=\"$name\">";
	

	$html .= "</form>";
	print $html;
}#takeSurvey

sub dumpQuery
{
	print "<table border>";
	foreach ($q->param())
	{
		print "<tr><td>$_<td>" . $q->param($_) . "\n";
	}	
	print "</table border>";
}
sub vote
{
	if (! &isInvited($code))
	{
		print "<b>You have not been invited to this survey !</b>";
		return;
	}
	if (&hasAlreadyVoted($code))
	{
		#Links to change vote, view vote or view results
		print "<b>You have already voted for this survey.</b>";
		print "<br>To view the results of this survey go here:";
		print "<a href='" . &getViewResultsUrl . "'>" . &getViewResultsUrl . "</a>";
		return;
	}
	if ($DEBUG)
	{
	print "<br><b>-Has Voted $code:</b>";
	if (&hasAlreadyVoted($code))
	{
		print "YES";
	}
	else
	{
		print "NO";
	}
	print "<br><b>is invited $code:</b>";
	if (&isInvited($code))
	{
		print "YES";
	}
	else
	{
		print "NO";
	}	
	&dumpQuery;
	@votelines = &getVoteLines();
	$count = @votelines;
	print "<h2>OOPS $count VOTELINES</h2>";
	print "<hr><b>Adding these lines:</b><br>" . &newLinesToBr(@votelines);
	}
	
	&appendToSurveyFile(&getVoteLines());
	print "Thank you for voting.  To see the results click here:";
	print &getViewResultsHtml;

}
sub isInvited
{
	$code = shift;
	$number =	grep(/^SURVEY_INVITED\|.*\|$code$/,@FILE_LINES);
	return $number;
}
sub hasAlreadyVoted
{
	$code = shift;
	$number =	grep(/^SURVEY_ANSWER\|.*\|$code\|/,@FILE_LINES);
	return $number;
}
#SURVEY_ANSWER|2|abcdefghij|Mon|Tues|Wed
sub getVoteLines
{
	my $string = "";
	my @fileLines = ();
	foreach ($q->param())
	{
		#&printlnHtml("<br>Examine:$_");
		if (/answer-(\d{1,2})/)
		{
			#&printlnHtml("MATCH");
			$i = $1;
			@allanswers = $q->param($_);
			if (! $fileLines[$i])
			{

				#&printlnHtml("LINE $i CREATED");
				$fileLines[$i] = "SURVEY_ANSWER|" . $i . "|" . $q->param('code');
			}
			foreach $a (@allanswers)
			{
				next if (! $a);
				#&printlnHtml("PROCESS ANSWER: $a");
				$a =~ s/\n/ /g; 
				#&printlnHtml("GOT HERE");
				if (isMultipleQuestion($i))
				{
					$fileLines[$i] .= "|$a";
				}
				else
				{
					$fileLines[$i] = "SURVEY_ANSWER|" . $i . "|" . $q->param('code') . "|$a";
				}
				#&printlnHtml("LINE $i is now:".$fileLines[$i]);
			}
		}
		else
		{
			#&printlnHtml("NO MATCH");
			$string .= " $_ has nothing";
		}
	}
	return join ("\n",@fileLines);
}
sub dumpEnv
{
	foreach $var (sort(keys(%ENV))) {
	$val = $ENV{$var};
	$val =~ s|\n|\\n|g;
	$val =~ s|"|\\"|g;
	print "${var}=\"${val}\"<br>\n";
	}
}

sub isMultipleQuestion
{
	my $index = shift;
	my $number =	grep(/^SURVEY_QUESTION\|$index\|MULTIPLE/,@FILE_LINES);
	return $number;
}#isMultiple


#
# Question (normal): 
#   Answer 1: #instances % (list of voters)
#   Answer 2: #instances % (list of voters)
#
# Question (freeform):
#   Answer 1: (voter)
#   Answer 2: (voter)
#
# Psuedocode:
# foreach Question
#   print Questions
#   if TEXT
#     foreach answer
#       print answer and who it is from
#     endfor
#   else (not TEXT)
#     foreach (unique answer in bunch)
#       print answer, # instances, %total vote, list of voters
#     endfor
#   endif
sub viewResults
{
	$numberInvited = keys(%INVITED_IDS);
	$numberRespondants = @RESPONDANT_IDS;
	if ($numberInvited > 0)
	{
		$percentResponded = 100 * $numberRespondants / $numberInvited;
	}
	else
	{
		$percentResponded = 0;
	}
	$i = 0;
	print "$numberRespondants of $numberInvited people have responded to this survey (" . sprintf("%.2f",$percentResponded) . " %)";
	print "<ol>";
	foreach $question_hashref (@{$QUESTIONS})
	{
		if (!$question_hashref)
		{
			next;	
		}	
		print "<li><b><i>" . $question_hashref->{"TEXT"} . "</i></b>" ;
		if ($question_hashref->{"TYPE"} eq "TEXT")
		{
	 		$answer_hashref = $question_hashref->{"ANSWERS"};
			foreach $key (keys (%{$answer_hashref}))
			{
         			$a = join(" ",@{$question_hashref->{"ANSWERS"}->{$key}});
				print "<br>" . $a . " (" . &getEmail($key) . ")";
			}
		}
		else
		{
	 		$tally_hashref = $question_hashref->{"TALLY"};
			println("<table border>");
			foreach $key (keys (%{$tally_hashref}))
			{
				$count = @{$tally_hashref->{$key}};
	 			$total = $question_hashref->{"TOTAL_VOTES"};
				$percent = ($count * 100 / $total) unless (!$total); 
				println ("<tr><th>$key<td>$count votes<td>");

				@voterlist = ();
				foreach $v (@{$tally_hashref->{$key}})
				{
					push @voterlist, &getEmail($v);
				}
				print "<td>", join(", ",
					@voterlist);

				print "<td>", &getBarHtml($percent);
			}
			println("</table>");
		}
		
		$i++;
	}
	print "</ol>";
	print "<hr>" . &fileToHtml("surveydata" . "/" . $q->param('name') . ".txt") unless (! $DEBUG);

	print "<b>The following people have not yet responded:</b><br>" unless (!@NOSHOW_EMAILS);
       	foreach(@NOSHOW_EMAILS)
	{
		print "<a href='mailto:" . $_ . "'>$_</a><br>";
	}
}#viewResults

sub getEmail
{
	my $k = shift;
	return $INVITED_IDS{$k};
}
sub getInvitedEmails
{

	return values(%INVITED_IDS);
}
sub getRespondedEmails
{
}

#----
#

sub sendEmail
{
	($to,$from,$cc,$subject,$msg) = @_;
	$mail = "";
	$mail .= "To: ". $to . "\n";
	$mail .= "From: ". $from . "\n";
	$mail .= "Cc: jwerwath\@novarra.com\n";
	$mail .= "Subject:" . $subject . "\n";
	$mail .= "\n\n";
	$mail .= $msg. " \n";
	if (! $REAL_EMAIL)
	{
		print "<hr>This message sent to $to from $from cc $cc subject $subject:</br>";# unless (!$DEBUG);
		print &newLinesToBr($mail);# unless (!$DEBUG);
		
		return;
	}
	if( open(MAIL,"|$SENDMAIL -t"))
	{
		print MAIL $mail;
		close(MAIL);
 	}
	else
	{
 		print "ERROR: Mail not sent !";
	}
}#sendMail

sub createSurvey
{
  $q = shift;
	$i = 0;
	$linesForFile = "";
	
	$adminEmail = $q->param("adminEmail");
	$linesForFile .= "SURVEY_ADMIN_EMAIL|" . $adminEmail . "\n";

	$origname = $q->param('surveyName');
	$surveyName = &nameToSurveyId($origname);
	$linesForFile .= "SURVEY_NAME|" . $sureyName . "\n";
	
	$invite = $q->param('invite');
	$invite =~ s/\n/\%20/g; # newlines to pipe for storage
	$linesForFile .= "SURVEY_INVITE|" . $invite . "\n";
	

	%INVITED_EMAILS= (); #email to ids	
	foreach (&getInviteEmails($q))
	{
		$INVITED_EMAILS{$_} = &randomPassword;
	}
	foreach (keys(%INVITED_EMAILS))
	{
		$linesForFile .= "SURVEY_INVITED|" . $_ . "|" . $INVITED_EMAILS{$_} . "\n";
	}
		
	for ($i = 1;$i <= $MAX_QUESTIONS; $i++)
	{	  $toadd = &getQuestionLineForFile($q,$i);
	    $linesForFile .= $toadd . "\n";
	}#end for
	

	


	&writeSurveyFile($surveyName,$linesForFile);	
	print "<br><b>LINES:</b><br>" . &newLinesToBr($linesForFile) unless (! $DEBUG);
	@emails = &getInviteEmails($q);
	&sendEmails("Please Take my Survey here: ",@emails);

	print "<br>Survey is complete.  To view results, click here: " . &getViewResultsHtml;
}#createSurvey

sub sendEmails #($message,@emails)
{
   my $message = shift;
	 my @emails = @_;
	 	foreach $email (@emails)
	{
		$id = $INVITED_EMAILS{$email};
		$msgurl = $MY_URL . "?code=" . $id . "&name=" . $surveyName . "&action=Take%20Survey%20Form";
		$msga = "Click here to vote: <a href='" . $msgurl . "'>" . $msgurl . "</a>";		
		$msg = $q->param('invite');
		$msg = $msg . "\n\n" . $message . "\nFollow this url to vote: " . $msgurl;

		sendEmail($email,$FROM_EMAIL,"","Survey:$origname ballot for $email",$msg);
		print "$email is invited.<br>";

		if (! $REAL_EMAIL)
		{
			&appendToLinksFile($msga);
		}
	} 
}#sendEmails

sub getSurveyFileName
{
	my $name = shift;
	if (! $name)
	{
		$name = $q->param('name');
	}
	return "surveydata" . "/" . $name . ".txt";
}
sub appendToSurveyFile
{
	my $what = shift;
	my $fname = getSurveyFileName();
	if (open(F,">>$fname"))
	{
		print F "$what\n";
		close F;
		print "Appended the following to $fname:<br>" . $what unless ( ! $DEBUG);
	}
	else
	{
		print "<h2>Oops: appendToSurveyFile $fname $! </h2>";
	}
}
sub appendToLinksFile
{
	my $text = shift;
	my $fname = "surveydata/links.txt";
	if (! -e $fname)
	{
		open(F,">$fname");
		print F "$text\n";
		close F;

	}
	elsif (open(F,">>$fname"))
	{
		print F "$text\n";
		close F;
	}
	else
	{
		#FIXME DO SOMETHING
		print "<h2>OOPS !" . $! . "</h2>";
	}	
}
sub simulateEmail
{
	print "<h3>Email simulation</h3>";
	print &getLinksFile;
}
sub getLinksFile
{
	my $fname = "surveydata/links.txt";
	if (open(F,"$fname"))
	{
		@linkslines = (<F>);
		close F;
		return join("<br>",@linkslines);
	}
	return "bad news - links file not there";
}
sub writeSurveyFile
{
	my $name = shift;
	my $text = shift;
	my $fname = "surveydata/" . $name . ".txt";
	if (open(F,">$fname"))
	{
		print F $text;
		close F;
	}
	else
	{
		#FIXME DO SOMETHING
		print "<h2>OOPS !" . $! . "</h2>";
	}	
}

sub topOfEveryPage
{
	if ($surveyName =~ /jrw/)
	{
	$top = "<a href='$MY_URL'>ADMIN</a>";
	$top .= " code=$code";
	$top .= " realemail=$REAL_EMAIL";
	$top .= "<hr>";
	}
	else
	{
		$top ="";
	}

	return $top;
}

sub getSurveyFileAsHtml
{
	return &fileToHtml(&getSurveyFileName());
}
sub fileToHtml
{
	my $fname = shift;
	if (open (F,$fname))
	{
		@flines = (<F>);
		close F;
		return "<pre>" . join ("<br>",@flines) . "</pre>";
	}
	else
	{
		return "Error: $fname could not be read $!";
	}
}
sub getViewResultsHtml
{
	return "<a href='" . &getViewResultsUrl . "'>" . &getViewResultsUrl . "</a>";
}
sub getViewResultsUrl
{
	$name = $q->param('name') unless $name;
	$MY_URL . "?name=" . $name . "&action=View+Results";
}

sub getBarHtml
{
	my $percent = shift;
	my $width = $percent * 3;
	return "<img border src='" . $BAR_IMAGE_FILE . "' height=10 width=" . $width . "><br>" . sprintf("%.2f",$percent) . " %";
}
sub println
{
	print shift,"\n";
}
sub printCreateForm
{
	print <<CREATE_FORM;


<body>
<form method=post>
Survey Name:<input name=surveyName>
<table border>
<tr>
<th name=question>Question
<th name=type>Type
<th name=choices>Choices (please use commas to separate choices.  Note: this is not used for the TEXT type.)

<tr>
<th size=50 name=question><input size=50 name=question-1>
<th name=type><select name=type-1><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-1 size=50>
<tr>
<th size=50 name=question><input size=50 name=question-2>
<th name=type><select name=type-2><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-2 size=50>
<tr>
<th size=50 name=question><input size=50 name=question-3>
<th name=type><select name=type-3><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-3 size=50>

<tr>
<th size=50 name=question><input size=50 name=question-4>
<th name=type><select name=type-4><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-4 size=50>

<tr>
<th size=50 name=question><input size=50 name=question-5>
<th name=type><select name=type-5><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-5 size=50>

<tr>
<th size=50 name=question><input size=50 name=question-6>
<th name=type><select name=type-6><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-6 size=50>

<tr>
<th size=50 name=question><input size=50 name=question-7>
<th name=type><select name=type-7><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-7 size=50>

<tr>
<th size=50 name=question><input size=50 name=question-8>
<th name=type><select name=type-8><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-8 size=50>

<tr>
<th size=50 name=question><input size=50 name=question-9>
<th name=type><select name=type-9><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-9 size=50>

<tr>
<th size=50 name=question><input size=50 name=question-10>
<th name=type><select name=type-10><option value=SINGLE_SELECT>Single Select: Vote can choose only 1 option.<option value=SINGLE_SELECT_OR_OTHER>Single Select: Voter chooses 1 option adds their own<option value=MULTIPLE_SELECT>Multiple Select: Voter can choose more than 1 option<option value=MULTIPLE_SELECT_ANDOR_OTHER>Multiple Select: Voter can choose more than 1 option and/or add their own<option value=TEXT>Text: Voter can add any text they choose<option value=NUMERIC>Numeric: User must enter a number</select>
<th name=choices><input name=choices-10 size=50>







</table>
Enter a comma delimeted list of email addresses to invite to this survey.
(whitespace will be ignored)
<textarea rows=5 cols=100 name=inviteList>
jerry\@foo.com,billy\@corgan.org,mc5\@detroit.us
</textarea>
<P>
Enter a message to invite people to your survey:
<br>
<textarea rows=5 cols=100 name=invite>
Please take my cool survey !
</textarea>
<br>
Admin Email:<input name=adminEmail>
Admin Password:<input type=password name=password>
<input type=submit name=action value="Create Survey">
<input type=reset>
</form>
</body>
</html>
CREATE_FORM
}

sub printlnHtml
{
	$msg = shift;
	print $msg, "<br>\n";
}
sub validEmailAddr { #check if e-mail address format is valid

  my $mail = shift;                                                  #in form name@host

  return 0 if ( $mail !~ /^[0-9a-zA-Z\.\-\_]+\@[0-9a-zA-Z\.\-]+$/ ); #characters allowed on name: 0-9a-Z-._ on host: 0-9a-Z-. on between: @

  return 0 if ( $mail =~ /^[^0-9a-zA-Z]|[^0-9a-zA-Z]$/);             #must start or end with alpha or num

  return 0 if ( $mail !~ /([0-9a-zA-Z]{1})\@./ );                    #name must end with alpha or num

  return 0 if ( $mail !~ /.\@([0-9a-zA-Z]{1})/ );                    #host must start with alpha or num

  return 0 if ( $mail =~ /.\.\-.|.\-\..|.\.\..|.\-\-./g );           #pair .- or -. or -- or .. not allowed

  return 0 if ( $mail =~ /.\.\_.|.\-\_.|.\_\..|.\_\-.|.\_\_./g );    #pair ._ or -_ or _. or _- or __ not allowed

  return 0 if ( $mail !~ /\.([a-zA-Z]{2,3})$/ );                     #host must end with '.' plus 2 or 3 alpha for TopLevelDomain (MUST be modified in future!)

  return 1;
}

#
#----

########################## SAMPLE FILE ######################################
#
#
#SURVEY_NAME|Sample
#SURVEY_ADMIN_EMAIL|joe@blow.com
#SURVEY_INVITE|Please take my survey.
#SURVEY_QUESTION|1|SINGLE_SELECT|What is your favorite color?|white|brown|black|red|green
#SURVEY_QUESTION|2|MULTIPLE_SELECT|What nights of the week are your free ?|Sun|Mon|Tues|Wed|Thurs|Fri|Sat
#SURVEY_QUESTION|3|SINGLE_SELECT_OR_OTHER|What is your species ?|Human|Vulcan
#SURVEY_QUESTION|4|MULTIPLE_SELECT_ANDOR_OTHER|Who do you love ?|Sally|John|Betty|Dan
#SURVEY_QUESTION|5|TEXT|What is your favorite Quote ?|
#
#
#SURVEY_INVITED|jim@scissorsoft.com|abcdefghij
#SURVEY_INVITED|werwath@hotmail.com|1234567890
#SURVEY_INVITED|jwerwath@novarra.com|ABCDEFGHIJ
#
#SURVEY_ANSWER|1|abcdefghij|brown
#SURVEY_ANSWER|2|abcdefghij|Mon|Tues|Wed
#SURVEY_ANSWER|3|abcdefghij|Human
#SURVEY_ANSWER|4|abcdefghij|Sally|Kerry
#SURVEY_ANSWER|5|abcdefghij|Let Go
#
#SURVEY_ANSWER|1|1234567890|brown
#SURVEY_ANSWER|2|1234567890|Mon|Sun|Sat
#SURVEY_ANSWER|3|1234567890|Human
#SURVEY_ANSWER|4|1234567890|Sally|Jon
#SURVEY_ANSWER|5|1234567890|I dont know
#

#SURVEY_STATUS|NEW
