#!/usr/bin/perl

use IMAP::Admin;
use strict;
use warnings;
use Mail::Mailer;
use Mail::Mailer qw(mail);

my $quota_cry = 80;
my $quota_max = 98;
my $url = "http://www.uptime.at/cgi-bin/quota.cgi";

sub main() {
    my $imap = IMAP::Admin->new('Server'    => 'localhost',
                            'Login'     => 'cyrus',
                            'Password'  => 'abcdefg',
                            'Port'      => 143,
                            'Separator' => ".",
                           );

    my @list = $imap->list("user.*");
    foreach my $box (@list) {
        my @quota = $imap->get_quota($box);

        if($quota[2] && $quota[1]) {
            #print "$box\nquota: ".$quota[1]."/".$quota[2]."\n";
            if($quota[1] / ($quota[2]/100) > $quota_cry ) {
                my $mailer = new Mail::Mailer 'smtp', Server => "localhost";
                my $username = $box;
                $username =~ s/user\.//;
                print "Processing $username and sending mail!\n";
                my $act_quota = $quota[1] / ($quota[2]/100);
                my $body_text_head = <<EOBTXT;
Sehr geehrter Mail-User $username!

Wir moechten Sie darauf hinweisen, dass
ihre Mailbox bereits zu $act_quota\% voll ist.

Diese Mail wird taeglich versendet, bis ihre Quota
wieder unter $quota_cry\% gefallen ist.

Den momentan benutzten Speicherplatz koennen sie auf

$url

abrufen und ueberpruefen.

Mit freundlichem Gruss,
UPtime SysAdmin
mailto:admin\@uptime.at
EOBTXT
                $mailer->open({ From    => '<admin@uptime.at> UPtime SysAdmin',
                                To      => "$username\@uptime.at",
                                Subject => "Quota over $quota_cry percent" }) || die "Can\'t open mailhandler!\n";
                
                print $mailer $body_text_head;
                $mailer->close;
                if($act_quota > $quota_max) {
                    print "Processing $username and sending mail to admin!\n";
                    $mailer->open({ From    => '<admin@uptime.at> UPtime SysAdmin',
                                    To      => 'admin@uptime.at',
                                    Subject => "User $username over $quota_max\%" }) || die "Can\'t open mailhandler!\n";
                    print $mailer "User has now $act_quota!";
                    $mailer->close;
                }
            }
        }

    }
    $imap->close;
}

&main();

