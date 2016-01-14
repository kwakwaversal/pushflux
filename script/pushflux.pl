#!/usr/bin/env perl

use strict;
use warnings;
use 5.010001;
use Data::Dumper;
use IPC::ConcurrencyLimit;
use Log::Unrotate;
use Mojo::UserAgent;

sub DEBUG { 1 }

my $buffer      = '100';                # flush buffer to influx after $buffer lines
my $mmin        = '-2';                 # find files modified in last 2 mins
my $monitor     = '/var/lib/pushflux';  # folder to monitor
my $monitor_ext = 'log';                # file extension to include in pushes
my $symlinks    = '-L';                 # find will follow symlinks
$monitor .= '/' unless $monitor =~ m,/$,;

run();
exit(0);

sub run {
  my $limit
    = IPC::ConcurrencyLimit->new(max_procs => 1, path => '/var/run/pushflux');

  my $id = $limit->get_lock;
  if (not $id) {
    warn "Another process appears to be still running. Exiting.\n";
    exit(0);
  }
  else {
    my @changed = `find $symlinks $monitor -type f -name '*.$monitor_ext' -mmin $mmin`;
    for my $filename (@changed) {
        chomp $filename;
        say "pushflux: $filename";
        pushflux(args_from_filename($monitor, $filename));
    }
  }

  # lock released with $limit going out of scope here
}

sub args_from_filename {
  my ($monitor, $filename) = @_;
  die "$monitor does not exist within $filename"
    unless $filename =~ m,^$monitor,;

  my ($host, $database, $log) = ($filename =~ m,^$monitor(.*?)/(.*?)/(.*?)$,);
  return ($host, $database, $log, $filename);
}

sub influx {
  my ($host, $database, $payload) = @_;

  say "Writing payload:";
  say $payload;

  state $ua = Mojo::UserAgent->new;
  my $tx = $ua->post("http://$host:8086/write?db=$database" => $payload);
  if (my $res = $tx->success) { return 0 }
  else {
    my $err = $tx->error;
    die("$err->{code} response: $err->{message}") if $err->{code};
    die("Connection error: $err->{message}");
  }
}

sub pushflux {
  my ($host, $database, $log, $filename) = @_;
  my $reader   = Log::Unrotate->new(
    {log => $filename, pos => "/tmp/$host-$database-$log.pos"});

  my $payload = undef;
  my $count   = 0;

  while (my $line = $reader->read()) {
    $payload .= $line;

    # every 100 lines are submitted to influx
    if (++$count % $buffer == 0) {
      if (influx($host, $database, $payload) == 0) {
        $payload = undef;
        $reader->commit();
      }
    }
  }

  if ($payload) {
    if (influx($host, $database, $payload) == 0) {
      $reader->commit();
    }
  }
}
