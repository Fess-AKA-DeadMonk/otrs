# --
# Kernel/System/SLA.pm - all sla function
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: SLA.pm,v 1.8 2007-05-24 07:38:11 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::SLA;

use strict;

use Kernel::System::Valid;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.8 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::SLA - sla lib

=head1 SYNOPSIS

All sla functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create a object

    use Kernel::Config;
    use Kernel::System::Log;
    use Kernel::System::DB;
    use Kernel::System::Service;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        LogObject => $LogObject,
    );
    my $SLAObject = Kernel::System::SLA->new(
        ConfigObject => $ConfigObject,
        LogObject => $LogObject,
        DBObject => $DBObject,
    );

=cut

sub new {
    my $Type = shift;
    my %Param = @_;
    # allocate new hash for object
    my $Self = {};
    bless ($Self, $Type);
    # check needed objects
    foreach (qw(DBObject ConfigObject LogObject TimeObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }
    $Self->{ValidObject} = Kernel::System::Valid->new(%Param);

    return $Self;
}

=item SLAList()

return a hash list of slas

    my %SLAList = $SLAObject->SLAList(
        ServiceID => 1,  # (optional)
        Valid => 0,      # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub SLAList {
    my $Self = shift;
    my %Param = @_;
    my %SLAList;
    # check needed stuff
    foreach (qw(UserID)) {
        if (!$Param{$_}) {
            $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
            return;
        }
    }
    # check valid param
    if (!defined($Param{Valid})) {
        $Param{Valid} = 1;
    }
    # quote
    foreach (qw(UserID)) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_}, 'Integer');
    }
    # check ServiceID
    my $Where = '';
    if ($Param{ServiceID}) {
        $Param{ServiceID} = $Self->{DBObject}->Quote($Param{ServiceID}, 'Integer');
        $Where .= "WHERE service_id = $Param{ServiceID} ";
    }
    # add valid part
    if ($Param{Valid}) {
        if ($Where) {
            $Where .= "AND ";
        }
        else {
            $Where .= "WHERE ";
        }
        $Where .= "valid_id IN ( ${\(join ', ', $Self->{ValidObject}->ValidIDsGet())} )";
    }
    # ask database
    $Self->{DBObject}->Prepare(
        SQL => "SELECT id, name FROM sla $Where",
    );
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $SLAList{$Row[0]} = $Row[1];
    }

    return %SLAList;
}

=item SLAGet()

return a sla as hash

Return
    $SLAData{SLAID}
    $SLAData{ServiceID}
    $SLAData{Name}
    $SLAData{Calendar}
    $SLAData{FirstResponseTime}
    $SLAData{UpdateTime}
    $SLAData{SolutionTime}
    $SLAData{ValidID}
    $SLAData{Comment}
    $SLAData{CreateTime}
    $SLAData{CreateBy}
    $SLAData{ChangeTime}
    $SLAData{ChangeBy}

    my %SLAData = $SLAObject->SLAGet(
        SLAID => 123,
        UserID => 1,
    );

=cut

sub SLAGet {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SLAID UserID)) {
        if (!$Param{$_}) {
            $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
            return;
        }
    }
    # quote
    foreach (qw(SLAID UserID)) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_}, 'Integer');
    }
    # get sla from db
    my %SLAData = ();
    $Self->{DBObject}->Prepare(
        SQL => "SELECT id, service_id, name, calendar_name, first_response_time, update_time, solution_time, ".
            "valid_id, comments, create_time, create_by, change_time, change_by ".
            "FROM sla WHERE id = $Param{SLAID}",
        Limit => 1,
    );
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $SLAData{SLAID} = $Row[0];
        $SLAData{ServiceID} = $Row[1];
        $SLAData{Name} = $Row[2];
        $SLAData{Calendar} = $Row[3] || '';
        $SLAData{FirstResponseTime} = $Row[4];
        $SLAData{UpdateTime} = $Row[5];
        $SLAData{SolutionTime} = $Row[6];
        $SLAData{ValidID} = $Row[7];
        $SLAData{Comment} = $Row[8];
        $SLAData{CreateTime} = $Row[9];
        $SLAData{CreateBy} = $Row[10];
        $SLAData{ChangeTime} = $Row[11];
        $SLAData{ChangeBy} = $Row[12];
    }
    return %SLAData;
}

=item SLALookup()

return a sla id, name and service_id

    my $SLAName = $SLAObject->SLALookup(
        SLAID => 123,
    );

    or

    my $SLAID = $SLAObject->SLALookup(
        Name => 'SLA Name',
    );

=cut

sub SLALookup {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    if (!$Param{SLAID} && !$Param{Name}) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need SLAID or Name!");
        return;
    }
    if ($Param{SLAID}) {
        my $Name;
        # quote
        $Param{SLAID} = $Self->{DBObject}->Quote($Param{SLAID}, 'Integer');
        # lookup
        $Self->{DBObject}->Prepare(
            SQL => "SELECT name FROM sla WHERE id = $Param{SLAID}",
            Limit => 1,
        );
        while (my @Row = $Self->{DBObject}->FetchrowArray()) {
            $Name = $Row[0];
        }
        return $Name;
    }
    else {
        my $ID;
        # quote
        $Param{Name} = $Self->{DBObject}->Quote($Param{Name});
        # lookup
        $Self->{DBObject}->Prepare(
            SQL => "SELECT id FROM sla WHERE name = '$Param{Name}'",
            Limit => 1,
        );
        while (my @Row = $Self->{DBObject}->FetchrowArray()) {
            $ID = $Row[0];
        }
        return $ID;
    }
}

=item SLAAdd()

add a sla

    my $SLAID = $SLAObject->SLAAdd(
        ServiceID => 1,
        Name => 'Service Name',
        Calendar => 'Calendar1',   # (optional)
        FirstResponseTime => 120,
        UpdateTime => 180,
        SolutionTime => 580,
        ValidID => 1,
        Comment => 'Comment',      # (optional)
        UserID => 1,
    );

=cut

sub SLAAdd {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(ServiceID Name ValidID UserID)) {
        if (!$Param{$_}) {
            $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
            return;
        }
    }
    # check escalation times
    foreach (qw(FirstResponseTime UpdateTime SolutionTime)) {
        if (!$Param{$_}) {
            $Param{$_} = 0;
        }
    }
    # quote
    foreach (qw(Name Calendar Comment)) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    foreach (qw(ServiceID FirstResponseTime UpdateTime SolutionTime ValidID UserID)) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_}, 'Integer');
    }
    # add sla to database
    my $CurrentTime = $Self->{TimeObject}->CurrentTimestamp();
    if ($Self->{DBObject}->Do(
        SQL =>"INSERT INTO sla ".
            "(service_id, name, calendar_name, first_response_time, update_time, solution_time, ".
            "valid_id, comments, create_time, create_by, change_time, change_by) VALUES ".
            "($Param{ServiceID}, '$Param{Name}', '$Param{Calendar}', $Param{FirstResponseTime}, ".
            "$Param{UpdateTime}, $Param{SolutionTime}, $Param{ValidID}, '$Param{Comment}', ".
            "'$CurrentTime', $Param{UserID}, '$CurrentTime', $Param{UserID})",
    )) {
        # get sla id
        $Self->{DBObject}->Prepare(
            SQL => "SELECT id FROM sla WHERE name = '$Param{Name}' AND ".
                "create_time = '$CurrentTime' AND create_by = $Param{UserID} AND ".
                "change_time = '$CurrentTime' AND change_by = $Param{UserID}",
            Limit => 1,
        );
        my $SLAID;
        while (my @Row = $Self->{DBObject}->FetchrowArray()) {
            $SLAID = $Row[0];
        }
        return $SLAID;
    }
    else {
        return;
    }
}

=item SLAUpdate()

update a existing sla

    my $True = $SLAObject->SLAUpdate(
        SLAID => 2,
        ServiceID => 1,
        Name => 'Service Name',
        Calendar => 'Calendar1',
        FirstResponseTime => 120,
        UpdateTime => 120,
        SolutionTime => 180,
        ResponseTime => 560,
        ValidID => 1,
        Comment => 'Comment', # (optional)
        UserID => 1,
    );

=cut

sub SLAUpdate {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SLAID ServiceID Name ValidID UserID)) {
        if (!$Param{$_}) {
            $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
            return;
        }
    }
    # check escalation times
    foreach (qw(FirstResponseTime UpdateTime SolutionTime)) {
        if (!$Param{$_}) {
            $Param{$_} = 0;
        }
    }
    # quote
    foreach (qw(Name Calendar Comment)) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    foreach (qw(ServiceID FirstResponseTime UpdateTime SolutionTime ValidID UserID)) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_}, 'Integer');
    }
    # update service
    return $Self->{DBObject}->Do(
        SQL => "UPDATE sla SET service_id = $Param{ServiceID}, name = '$Param{Name}', ".
            "calendar_name = '$Param{Calendar}', first_response_time = $Param{FirstResponseTime}, ".
            "update_time = $Param{UpdateTime}, ".
            "solution_time = $Param{SolutionTime}, valid_id = $Param{ValidID}, ".
            "comments = '$Param{Comment}', change_time = current_timestamp, change_by = $Param{UserID} ".
            "WHERE id = $Param{SLAID}",
    );
}

1;

=back

=head1 TERMS AND CONDITIONS

This Software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.8 $ $Date: 2007-05-24 07:38:11 $

=cut
