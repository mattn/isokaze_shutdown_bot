#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Furl;
use Digest::SHA1 qw/sha1_hex/;
use Encode;
use DateTime::Format::Strptime;
use Time::Local;

my $secret = $ENV{ISOKAZE_SHUTDOWN_BOT_SECRET};

my @t = localtime(time);
my $year = 1900 + $t[5];

my $parser = DateTime::Format::Strptime->new(
  pattern => '%Y %a %b %d %H:%M',
  on_error => 'croak',
  time_zone => sprintf("+%02d00", (timegm(@t) - timelocal(@t)) / 3600),
);

my $ua = Furl->new(agent => $0, timeout => 10);
$ua->env_proxy;
while (1) {
  sleep 3;
  my $last_shutdown = `last -x shutdown reboot mattn | head -1`;
  $last_shutdown = substr($last_shutdown, 39, 16);
  #warn "$year $last_shutdown";
  my $dt = $parser->parse_datetime("$year $last_shutdown");
  my $diff = time - $dt->epoch;
  next if $diff < 0 || $diff > 10;
  warn "shutdown!";

  my $msg = "isokaze がシャットダウンします!";
  my $res = $ua->post('http://lingr.com/api/room/say', [], [
      room => 'computer_science',
      bot  => 'isokaze_shutdown_bot',
      bot_verifier => sha1_hex('isokaze_shutdown_bot' . $secret),
      text => encode_utf8($msg),
  ]);
  last;
}
