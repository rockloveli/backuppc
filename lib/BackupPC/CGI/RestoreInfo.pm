#============================================================= -*-perl-*-
#
# BackupPC::CGI::RestoreInfo package
#
# DESCRIPTION
#
#   This module implements the RestoreInfo action for the CGI interface.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#
# COPYRIGHT
#   Copyright (C) 2003  Craig Barratt
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#========================================================================
#
# Version 2.1.0, released 20 Jun 2004.
#
# See http://backuppc.sourceforge.net.
#
#========================================================================

package BackupPC::CGI::RestoreInfo;

use strict;
use BackupPC::CGI::Lib qw(:all);

sub action
{
    my $Privileged = CheckPermission($In{host});
    my $host = $1 if ( $In{host} =~ /(.*)/ );
    my $num  = $In{num};
    my $i;

    if ( !$Privileged ) {
        ErrorExit($Lang->{Only_privileged_users_can_view_restore_information});
    }
    #
    # Find the requested restore
    #
    my @Restores = $bpc->RestoreInfoRead($host);
    for ( $i = 0 ; $i < @Restores ; $i++ ) {
        last if ( $Restores[$i]{num} == $num );
    }
    if ( $i >= @Restores ) {
        ErrorExit(eval("qq{$Lang->{Restore_number__num_for_host__does_not_exist}}"));
    }

    %RestoreReq = ();
    do "$TopDir/pc/$host/RestoreInfo.$Restores[$i]{num}"
	    if ( -f "$TopDir/pc/$host/RestoreInfo.$Restores[$i]{num}" );

    my $startTime = timeStamp2($Restores[$i]{startTime});
    my $reqTime   = timeStamp2($RestoreReq{reqTime});
    my $dur       = $Restores[$i]{endTime} - $Restores[$i]{startTime};
    $dur          = 1 if ( $dur <= 0 );
    my $duration  = sprintf("%.1f", $dur / 60);
    my $MB        = sprintf("%.1f", $Restores[$i]{size} / (1024*1024));
    my $MBperSec  = sprintf("%.2f", $Restores[$i]{size} / (1024*1024*$dur));

    my $fileListStr = "";
    foreach my $f ( @{$RestoreReq{fileList}} ) {
	my $targetFile = $f;
	(my $strippedShareSrc  = $RestoreReq{shareSrc}) =~ s/^\///;
	(my $strippedShareDest = $RestoreReq{shareDest}) =~ s/^\///;
	substr($targetFile, 0, length($RestoreReq{pathHdrSrc}))
					= $RestoreReq{pathHdrDest};
	$targetFile =~ s{//+}{/}g;
	$fileListStr .= <<EOF;
<tr><td>$RestoreReq{hostSrc}:/$strippedShareSrc$f</td><td>$RestoreReq{hostDest}:/$strippedShareDest$targetFile</td></tr>
EOF
    }
    my $content = eval("qq{$Lang->{Restore___num_details_for__host2}}");
    Header(eval("qq{$Lang->{Restore___num_details_for__host}}"),$content);
    Trailer();
}

1;