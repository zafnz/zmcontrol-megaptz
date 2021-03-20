# ==========================================================================
#
# ZoneMinder MegavisionPTZ Module
#
# See bottom of file for manual
#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# ==========================================================================

package ZoneMinder::Control::MegaPTZ;

use 5.006;
use strict;
use warnings;
use Data::Dumper;

use Time::HiRes qw( usleep );

require ZoneMinder::Base;
require ZoneMinder::Control;
require LWP::UserAgent;
use URI;

our @ISA = qw(ZoneMinder::Control);

use ZoneMinder::Logger qw(:all);
use ZoneMinder::Config qw(:all);

sub new {
  my $class = shift;
  my $id = shift;
  my $self = ZoneMinder::Control->new($id);
  $self->{moveDelay}  = 500;
  $self->{zoomDeley} = 100;
  $self->{irisDelay} = 100;
  $self->{focusDelay} = 100;
  bless($self, $class);
  return $self;
}

sub open {
  my $self = shift;

  $self->loadMonitor();

  if ($self->{Monitor}->{AutoStopTimeout} && $self->{Monitor}->{AutoStopTimeout} > 0) {
    $self->{moveDelay} = $self->{Monitor}->{AutoStopTimeout} / 1000;
    Info("Setting autostop to " . $self->{moveDelay})
  }

  if ( $self->{Monitor}->{ControlAddress} !~ /^\w+:\/\// ) {
    # Has no scheme at the beginning, so won't parse as a URI
    $self->{Monitor}->{ControlAddress} = 'http://'.$self->{Monitor}->{ControlAddress};
  }
  my $uri = URI->new($self->{Monitor}->{ControlAddress});

  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->agent('ZoneMinder Control Agent/'.ZoneMinder::Base::ZM_VERSION);
  my ( $username, $password );
  my $realm = 'Login to ' . $self->{Monitor}->{ControlDevice};
  if ( $self->{Monitor}->{ControlAddress} ) {
    ( $username, $password ) = $uri->authority() =~ /^(.*):(.*)@(.*)$/;

    $$self{address} = $uri->host_port();
    $self->{ua}->credentials($uri->host_port(), $realm, $username, $password);
    # Testing seems to show that we need the username/password in each url as well as credentials
    $$self{base_url} = $uri->canonical();
    Debug('Using initial credentials for '.$uri->host_port().", $realm, $username, $password, base_url: $$self{base_url} auth:".$uri->authority());
  }

  my $res = $self->{ua}->get($$self{base_url}.'browse/index.asp');

  if ( $res->is_success ) {
    $self->{state} = 'open';
    return;
  }

  if ( $res->status_line() eq '401 Unauthorized' ) {
    Error('Authentication failed');
    Error("Failed to get " . $$self{base_url} . "browse/index.asp ".$res->status_line());
  } 

  $self->{state} = 'closed';
}

sub close {
  my $self = shift;
  $self->{state} = 'closed';
}

sub sendCmdWithStop {
  my $self = shift;
  my $cmd = shift;
  my $delay = shift || $self->{moveDelay};

  $self->sendCmd($cmd);
  usleep($delay);
  return $self->sendCmd(0);
}

sub sendCmd {
  my $self = shift;
  my $cmd = shift;
  my $result = undef;

  my $url = $$self{base_url} . 'form/setPTZCfg?command=' . $cmd;
  my $res = $self->{ua}->get($url);

  if ( $res->is_success ) {
    $result = !undef;
    # Command to camera appears successful, write Info item to log
    Info("Camera control: \'".$res->status_line()."\' for command $cmd");
    $result = 1;
  } else {
    # Try again
    $res = $self->{ua}->get($url);
    if ( $res->is_success ) {
      # Command to camera appears successful, write Info item to log
      Info("Camera control (retry): \'".$res->status_line()."\' for command: $cmd");
      $result = 1;
    } else {
      Error('Camera control command FAILED: \''.$res->status_line().'\' for URL '.$url);
    }
  }
  return $result;
}
sub sendPresetCmd {
  my $self = shift;
  my $flag = shift;
  my $presetNum = shift;
  my $existFlag = 1;
  my $result = undef;

  my %params = (
    flag => $flag,
    existFlag => $existFlag,
    presetNum => $presetNum
  );
  my $url = $$self{base_url} . "form/presetSet?flag=$flag&existFlag=$existFlag&presetNum=$presetNum";

  my $res = $self->{ua}->get($url);

  if ( $res->is_success ) {
    $result = !undef;
    # Command to camera appears successful, write Info item to log
    Info("Camera control: \'".$res->status_line()."\' for  flag: $flag presetNum: $presetNum");
    # TODO: Add code to retrieve $res->message_decode or some such. Then we could do things like check the camera status.
  } else {
    Error('Camera control command FAILED: \''.$res->status_line().'\' for URL '.$url);
  }
  return $result;
}

sub reset {
  my $self = shift;
  my $result = undef;

  my $url = $$self{base_url} . '"form/reboot?language=en';
  my $res = $self->{ua}->get($url);

  if ( $res->is_success ) {
    $result = 1;
    # Command to camera appears successful, write Info item to log
    Info("Camera resetting");
  } else {
    Error('Camera control command FAILED: \''.$res->status_line().'\' for URL '.$url);
  }
  return $result;
}

sub moveConUp         { $_[0]->sendCmdWithStop(1) }
sub moveConDown       { $_[0]->sendCmdWithStop(2) }
sub moveConLeft       { $_[0]->sendCmdWithStop(3) }
sub moveConRight      { $_[0]->sendCmdWithStop(4) }
sub moveConDownLeft   { $_[0]->sendCmdWithStop(5) }
sub moveConUpLeft     { $_[0]->sendCmdWithStop(6) }
sub moveConUpRight    { $_[0]->sendCmdWithStop(7) }
sub moveConDownRight  { $_[0]->sendCmdWithStop(8) }
sub moveStop          { $_[0]->sendCmd(0) }

sub zoomConTele       { $_[0]->sendCmdWithStop(13, $_[0]->{zoomDelay}) }
sub zoomConWide       { $_[0]->sendCmdWithStop(14, $_[0]->{zoomDelay}) }
sub zoomStop          { $_[0]->sendCmd(0); }


sub irisConOpen { 
  my $self = shift;
  # A gradule step for a iris is send command, and then send the opp command
  $self->sendCmd(9);
  usleep($self->{irisDelay});
  $self->sendCmd(10);
}
sub irisConClose { 
  my $self = shift;
  $self->sendCmd(10);
  usleep($self->{irisDelay});
  $self->sendCmd(9);
}  
sub irisStop          { 
  # There is no irisStop 
}

sub focusConFar { 
  # A gradule step for a focus is send command, and then send the opp command
  my $self = shift;
  $self->sendCmd(11);
  usleep($self->{focusDelay});
  $self->sendCmd(12);
}
sub focusConNear { 
  my $self = shift;
  $self->sendCmd(12);
  usleep($self->{focusDelay});
  $self->sendCmd(11);
}  
sub focusStop  { 
  # There is no focusStop
}


sub presetHome {
  my $self = shift;
  Debug('Home Preset');
  $self->sendPresetCmd(4, 0)
}

sub presetGoto {
  my $self = shift;
  my $params = shift;
  my $preset = $self->getParam($params, 'preset');
  Info("Go To Preset $preset");
  $self->sendPresetCmd(4, $preset - 1);
}

sub presetSet {
  my $self = shift;
  my $params = shift;
  my $preset = $self->getParam($params, 'preset');
  Info('Set Preset');
  $self->sendPresetCmd(3, $preset - 1);
}


1;

__END__

=pod

=head1 NAME

ZoneMinder::Control::MegaPTZ - MegaPTZ camera control

=head1 DESCRIPTION

This module contains the implementation of the MegaPTZ Camera
controllable PTZ.

NOTE: This module implements interaction with the camera in clear text.

The login and password are transmitted from ZM to the camera in clear text,
and as such, this module should be used ONLY on a blind LAN implementation
where interception of the packets is very low risk.

The moveDelays make the camera move in steps, rather than continous.
This is a choice of mine. It is possible to change it to continous by
changing sendCmdWithStop to sendCmd 

=head1 INITIAL SETUP

Setting up this controller in ZM (only need to do once)

From any monitor

In the control tab

Next to Control Type, click Edit

Click Add New Controller

=head2 Configure as follows

=over 2

=item * Name: MegaPTZ

=item * Type: FFmpeg

=item * Protocol: MegaPTZ

=item * Can Reset: <Optional if you want it>

=item * On the other tabs, set the following:

=item * Can Move, Can Move Diagonolly, Can Move Continous

=item * Can Pan, Can Tilt, Can Zoom, Can Zoom Continuous

=item * Can Focus, Can Focus Continous

=item * Can Iris, Can Iris Continuous

=item * Has Presets, Can Set Presets. 

=item * Number of presets is whatever you like. 

20 is a good number, you really probably don't need more than that.

=back

=head1 MONITOR SETUP

Setup for each monitor

In the monitor's Control tab, set the following:

=over 5

=item * Controllable: Checked

=item * Control Type: MegaPTZ

=item * Control Address: <user>:<pass>@<ip-address>

=item * Auto Stop Timeout: 0.5

=back 

=head1 EXTRA INFO

If you're configuring a MegaPTZ, it is onvif compatible, 
but just to save you time:

Source for high res: 
   rtsp://admin:admin@<ip-address>:554/1/h264minor

Source for low res:
   rtsp://admin:admin@<ip-address>:554/1/h264major

=head1 SEE ALSO

Nothing. :(

=head1 AUTHORS

Nick Clifford <zaf@crypto.geek.nz>

=head1 COPYRIGHT AND LICENSE

(C) 2021 Nick Clifford

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
