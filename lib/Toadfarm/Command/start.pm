package Toadfarm::Command::start;

=head1 NAME

Toadfarm::Command::start - Start a Toadfarm DSL script

=head1 DESCRIPTION

L<Toadfarm::Command::start> is a command for starting a L<Toadfarm> application.

=head1 SYNOPSIS

  $ /path/to/script.pl start
  $ /path/to/script.pl start --tail <args>

=cut

use Mojo::Base 'Toadfarm::Command::tail';
use File::Basename 'dirname';
use File::Spec;

=head1 ATTRIBUTES

=head2 description

Short description of command, used for the command list.

=cut

has description => 'Toadfarm: Start the server if not already running';

=head1 METHODS

=head2 run

Run command.

=cut

sub run {
  my ($self, @args) = @_;
  my $moniker = $self->app->moniker;
  my $pid     = $self->_pid;
  my $timeout = 5;

  return $self->_exit("$moniker ($pid) already running.") if $pid and kill 0, $pid;

  if (grep {/^--tail/} @args) {
    exec $self->_hypnotoad, $0 unless fork;
    return $self->_tail(grep { !/^--tail/ } @args);
  }
  else {
    system $self->_hypnotoad, $0;
    my $exit = $? >> 8;
    return $self->_exit("$moniker failed to start. ($exit)", $exit) if $exit;

    while ($timeout--) {
      my $pid = $self->_pid or next;
      return $self->_exit("$moniker ($pid) started.") if $pid and kill 0, $pid;
    }
    continue {
      sleep 1;
    }
  }

  return $self->_exit("$moniker failed to start.", 3);
}

sub _hypnotoad {
  my $self = shift;

  for my $p (File::Spec->path, dirname($^X)) {
    my $exe = File::Spec->catfile($p, 'hypnotoad');
    return $exe if -r $exe;
  }

  die "Cannot find 'hypnotoad' in \$PATH.";
}

sub _pid {
  my $self    = shift;
  my $moniker = $self->app->moniker;
  my $file    = $self->app->config->{hypnotoad}{pid_file}
    or die "$moniker has invalid config: /hypnotoad/pid_file is not set.\n";
  return 0 unless $file and -e $file;
  open my $PID, '<', $file or die "Unable to read pid_file $file: $!\n";
  my $pid = join '', <$PID>;
  return $pid =~ /(\d+)/ ? $1 : 0;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
