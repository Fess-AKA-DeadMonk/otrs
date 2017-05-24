# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my %ForbiddenValueTypes = $Kernel::OM->Get('Kernel::System::SysConfig')->ForbiddenValueTypesGet();
$Self->IsDeeply(
    \%ForbiddenValueTypes,
    {
        Select => [
            "Option",
        ],
    },
    "Check forbidden value types.",
);

1;
