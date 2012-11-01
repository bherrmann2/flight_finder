#!perl
#
use LWP;

if ($#ARGV != 4)
{
  print "USAGE: perl send_image.pl <script_url> <image_file> <latency|response> <customer_id> <day|hour>\ne.g. perl send_image.pl http://127.0.0.1:8888/cgi-bin/upload.cgi foo.png latency 3hk day";
  exit;
}
my $b = LWP::UserAgent->new();
my $script = $ARGV[0];
my $image = $ARGV[1];
my $type = $ARGV[2];
my $customer_id = $ARGV[3];
my $time      = $ARGV[4];

my $resp = $b->post($script,['type' => $type, 'customer_id' => $customer_id, 'time' => $time, 'image' => [$image]],'Content_Type' => 'form-data');
print $resp->status_line();
