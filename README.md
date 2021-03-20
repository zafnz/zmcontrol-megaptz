# NAME

ZoneMinder::Control::MegaPTZ - MegaPTZ camera control

# DESCRIPTION

This module contains the implementation of the MegaPTZ Camera
controllable PTZ.

NOTE: This module implements interaction with the camera in clear text.

The login and password are transmitted from ZM to the camera in clear text,
and as such, this module should be used ONLY on a blind LAN implementation
where interception of the packets is very low risk.

The moveDelays make the camera move in steps, rather than continous.
This is a choice of mine. It is possible to change it to continous by
changing sendCmdWithStop to sendCmd 

# INITIAL SETUP

Setting up this controller in ZM (only need to do once)

From any monitor

In the control tab

Next to Control Type, click Edit

Click Add New Controller

## Configure as follows

- Name: MegaPTZ
- Type: FFmpeg
- Protocol: MegaPTZ
- Can Reset: <Optional if you want it>
- On the other tabs, set the following:
- Can Move, Can Move Diagonolly, Can Move Continous
- Can Pan, Can Tilt, Can Zoom, Can Zoom Continuous
- Can Focus, Can Focus Continous
- Can Iris, Can Iris Continuous
- Has Presets, Can Set Presets. 
- Number of presets is whatever you like. 

    20 is a good number, you really probably don't need more than that.

# MONITOR SETUP

Setup for each monitor

In the monitor's Control tab, set the following:

- Controllable: Checked
- Control Type: MegaPTZ
- Control Address: <user>:<pass>@<ip-address>
- Auto Stop Timeout: 0.5

# EXTRA INFO

If you're configuring a MegaPTZ, it is onvif compatible, 
but just to save you time:

Source for high res: 
   rtsp://admin:admin@<ip-address>:554/1/h264minor

Source for low res:
   rtsp://admin:admin@<ip-address>:554/1/h264major

# SEE ALSO

Nothing. :(

# AUTHORS

Nick Clifford <zaf@crypto.geek.nz>

# COPYRIGHT AND LICENSE

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
