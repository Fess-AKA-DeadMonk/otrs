#!/usr/bin/perl
# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';

use Getopt::Std;

use Kernel::System::ObjectManager;

# get options
my %Opts;
getopt( 'ndsajcf', \%Opts );
if ( $Opts{h} ) {
    print "otrs.UnitTest.pl - Run OTRS unit tests\n";
    print "Copyright (C) 2001-2017 OTRS AG, http://otrs.com/\n";
    print <<EOF;
Usage: otrs.UnitTest.pl
    [-n Name]          # Single Tests to run, e.g. 'Ticket', 'Queue', or 'Ticket:Queue'
    [-d Directory]     # Test directory to process
    [-s URL]           # Submit test results to unit test server
    [-a Auth]          # Authentication string for unit test server
    [-j JobID]         # Job ID for unit test submission to server
    [-c Scenario]      # Scenario identifier for unit test submission to server
    [-f Attachment]    # Send an additional file(s) to the server, e.g. '/path/to/UnitTest.log'
    [-v]               # Show details for all tests, not just failing
    [-e]               # Specify if command return code should not indicate if tests were ok/not ok,
                       # but if submission was successful instead
EOF
    exit 1;
}

# create object manager
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-otrs.UnitTest',
    },
);

my $FunctionResult = $Kernel::OM->Get('Kernel::System::UnitTest')->Run(
    Tests                  => $Opts{n} || '',
    Directory              => $Opts{d} || '',
    Verbose                => $Opts{v} || '',
    Product                => $Opts{p} || '',
    SubmitURL              => $Opts{s} || '',
    SubmitAuth             => $Opts{a} || '',
    SubmitResultAsExitCode => $Opts{e} || '',
    JobID                  => $Opts{j} || '',
    Scenario               => $Opts{c} || '',
    AttachmentPath         => $Opts{f} || '',
);

if ( !$FunctionResult ) {
    exit 1;
}

exit 0;
