#Copyright 2014 Carnegie Mellon University
#All rights reserved.

#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

#1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

#2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

#3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package CMU::ActiveMQ;
use Net::Stomp;
use Data::Dumper;
use strict;
use warnings;

require CMU::CFG;
require CMU::Stats;

my $_stomp;
my $_primary;
my $_secondary;
my $_port;
my $_login;
my $_password;
my $_ldapqueue;
my $_errorqueue;
my $_activemq = undef;

my $log = Log::Log4perl->get_logger();

sub new {
	$log->debug("Calling CMU::ActiveMQ::new()");
	my $class = shift;
	my $self  = {};
	$_activemq = bless $self, $class;

	CMU::CFG::readConfig('configuration.pl');
	$_activemq->{_primary}    = $CMU::CFG::_CFG{'activemq'}{'primary'};
	$_activemq->{_secondary}  = $CMU::CFG::_CFG{'activemq'}{'secondary'};
	$_activemq->{_port}       = $CMU::CFG::_CFG{'activemq'}{'port'};
	$_activemq->{_login}      = $CMU::CFG::_CFG{'activemq'}{'login'};
	$_activemq->{_password}   = $CMU::CFG::_CFG{'activemq'}{'password'};
	$_activemq->{_ldapqueue}  = $CMU::CFG::_CFG{'activemq'}{'ldapqueue'};
	$_activemq->{_errorqueue} = $CMU::CFG::_CFG{'activemq'}{'errorqueue'};
	$_activemq->connect();
	$_activemq->subscribe();

	return $_activemq;
}

sub getStomp {
	my ($self) = @_;

	$log->debug("Calling CMU::ActiveMQ::getStomp(self)");

	return $self->{_stomp};
}

sub sendToErrorQueue {
	my ( $self, $mesg ) = @_;

	$log->debug("Calling CMU::ActiveMQ::isConnected(self, $mesg)");
	eval {
		$self->{_stomp}->send(
			{
				destination => $self->{_errorqueue},
				body        => $mesg,
				persistent  => 'true'
			}
		);

	};
	if ($@) {
		$log->error( "Could not send message " . $mesg . " due to error :$!" );
		die();
	}
}

sub disconnect {
	my ($self) = @_;

	$log->debug("Calling CMU::ActiveMQ::disconnect(self)");

	if ( defined $self->{_stomp} ) {
		eval { $self->{_stomp}->disconnect(); };
		if ($@) {
			$log->error("Could not disconnect stomp connection because:$!");
		}
		undef $self->{_stomp};
		undef $_activemq;
	}
}

sub connect {
	my ($self) = @_;
	$log->debug("Calling CMU::ActiveMQ::connect()");

	eval {
		$self->{_stomp} = Net::Stomp->new(
			{
				hosts => [
					{
						hostname => $self->{_primary},
						port     => $self->{_port}
					},
					{
						hostname => $self->{_secondary},
						port     => $self->{_port}
					},
				],
				ssl => 1
			}
		);
	};

	if ($@) {
		$log->error("Could not create stomp instance because:$!");
		return;
	}

	$log->debug(
		"Connecting to stomp using login:$self->{_login} passcode:'xxxxxx'");

	eval {
		my $conn =
		  $self->{_stomp}->connect(
			{ login => $self->{_login}, passcode => $self->{_password} } );
	};

	if ($@) {
		$log->error("Could not create stomp connection because:$!");
		return;
	}

	$log->info("Connected to stomp server");

	return $self->{_stomp};
}

sub subscribe {
	my ($self) = @_;
	$log->debug("Calling CMU::ActiveMQ::subscribe(self)");

	eval {
		$self->{_stomp}
		  ->subscribe( { destination => $self->{_ldapqueue}, ack => 'client' },
			'activemq.prefetchSize' => 1 );
	};
	if ($@) {
		$log->error( "Couldn't subscribe to queue " . $self->{_ldapqueue} );
		die();
	}
}

sub processMessageChangeLog {
	my @groupermembers = ();
	my ( $self, $ldap, $data ) = @_;
	$log->debug(
		"Calling CMU::ActiveMQ::processMessageChangeLog(self, ldap, data)");

	eval {
		if ( defined $data->{"memberList"} )
		{
			@groupermembers = @{ $data->{"memberList"} };
		}

		my $groupdn = $ldap->getGroupDn( $data->{"name"} );

		if ( $data->{"operation"} eq "createGroup" ) {
			my @attrs = ("dn");
			my $entry =
			  $ldap->getLdapEntry(
				"(objectClass=" . $ldap->{_groupobjectclass} . ")",
				\@attrs, $groupdn );

			if ( !defined $entry ) {
				$ldap->createGroup($groupdn);
			}
			else {
				$log->info( "Skipping create group as group  " . $groupdn
					  . " already exists" );
			}
		}
		elsif ( $data->{"operation"} eq "addMember" ) {
			my $memberdn = $ldap->getMemberDn( $data->{"memberId"} );
			if ( defined $memberdn ) {
				$ldap->addGroupMember( $memberdn, $groupdn );
			}
			else {
				$log->info( "Skipping add member to " . $groupdn
					  . " as member "
					  . $data->{'memberId'}
					  . " doesn't exist " );
			}
		}
		elsif ( $data->{"operation"} eq "addIsMemberOf" ) {
			my $memberdn = $ldap->getMemberDn( $data->{"memberId"} );
			if ( defined $memberdn ) {
				$ldap->addIsMemberOf( $memberdn, $groupdn );
			}
			else {
				$log->info( "Skipping add isMemberOf to uid  "
					  . $data->{'memberId'}
					  . " as uid doesn't exist" );
			}
		}
		elsif ( $data->{"operation"} eq "removeMember" ) {
			my $memberdn = $ldap->getMemberDn( $data->{"memberId"} );
			if ( defined $memberdn ) {
				$ldap->removeGroupMember( $memberdn, $groupdn );
			}
			else {
				$log->info( "Skipping remove member from " . $groupdn
					  . " as uid "
					  . $data->{'memberId'}
					  . " doesn't exist" );
			}
		}
		elsif ( $data->{"operation"} eq "removeIsMemberOf" ) {
			my $memberdn = $ldap->getMemberDn( $data->{"memberId"} );
			if ( defined $memberdn ) {
				{
					$ldap->removeIsMemberOf( $memberdn, $groupdn );
				}
			}
			else {
				$log->info( "Skipping remove isMemberOf from uid  "
					  . $data->{'memberId'}
					  . " as uid doesn't exist" );
			}
		}
		elsif ( $data->{"operation"} eq "updateGroup" ) {
			if (   $data->{"description"} ne ''
				&& $data->{"olddescription"} eq '' )
			{
				$ldap->addGroupDescription( $groupdn, $data->{"description"} );
			}
			elsif ($data->{"description"} ne ''
				&& $data->{"olddescription"} ne '' )
			{
				$ldap->replaceGroupDescription( $groupdn,
					$data->{"olddescription"} );
			}
			elsif ($data->{"description"} eq ''
				&& $data->{"olddescription"} ne '' )
			{
				$ldap->removeGroupDescription($groupdn);
			}
			else {
				$log->info( "Skipping update group for " . $groupdn
					  . " as both old and new value for description is empty "
				);
			}
		}
		elsif ( $data->{"operation"} eq "deleteGroup" ) {
			$ldap->deleteObject($groupdn);
		}
		elsif ( $data->{"operation"} eq "deleteGroupIsMemberOf" ) {
			my $groupdn = $ldap->getGroupDn( $data->{"name"} );

			my @ldapmembers = $ldap->getUidByIsMemberOf($groupdn);

			foreach (@ldapmembers) {
				my $memberdn = $ldap->getMemberDn($_);
				if ( defined $memberdn ) {
					$ldap->removeIsMemberOf( $memberdn, $groupdn );
				}
			}
		}
		elsif ( $data->{"operation"} eq "renameGroup" ) {
			$log->info("Rename not handled...Skipping ActiveMQ message");
		}
	};
	if ($@) {
		die();
	}
}

sub processMessageFullSyncIsMemberOf {
	my @groupermembers            = ();
	my @ldapmembers               = ();
	my @add_ismemberof_members    = ();
	my @remove_ismemberof_members = ();

	my ( $self, $ldap, $data ) = @_;
	$log->debug(
"Calling CMU::ActiveMQ::processMessageFullSyncIsMemberOf(self, ldap, data)"
	);

	eval {
		my $ldaptarget = $ldap->getLdapTargetName();
		if ( defined $data->{"memberList"} ) {
			@groupermembers = @{ $data->{"memberList"} };
		}

		my $groupdn = $ldap->getGroupDn( $data->{"name"} );
		@ldapmembers            = $ldap->getUidByIsMemberOf($groupdn);
		@add_ismemberof_members =
		  CMU::Util::arrayMinus( \@groupermembers, \@ldapmembers );

		foreach (@add_ismemberof_members) {
			my $memberdn = $ldap->getMemberDn($_);
			if ( defined $memberdn ) {
				$ldap->addIsMemberOf( $memberdn, $groupdn );
			}
		}

		@remove_ismemberof_members =
		  CMU::Util::arrayMinus( \@ldapmembers, \@groupermembers );

		foreach (@remove_ismemberof_members) {
			my $memberdn = $ldap->getMemberDn($_);
			if ( defined $memberdn ) {
				$ldap->removeIsMemberOf( $memberdn, $groupdn );
			}
		}

		$log->info( "Grouper members count: "
			  . scalar @groupermembers . " for "
			  . $data->{'name'} );
		$log->info( "LDAP member count: "
			  . scalar @ldapmembers
			  . " by isMemberOf for "
			  . $groupdn );
		$log->info( "Add isMemberOf count: "
			  . scalar @add_ismemberof_members . " for "
			  . $data->{'name'} );
		$log->info( "Remove isMemberOf count: "
			  . scalar @remove_ismemberof_members . " for "
			  . $data->{'name'} );
		$log->info( "FullsyncIsMemberOf completed successfully for "
			  . $data->{'name'} );

	};
	if ($@) {
		die();
	}
}

sub processMessageFullSync {
	my @groupermembers  = ();
	my @ldapuidmembers  = ();
	my @ldapmembers     = ();
	my @add_members     = ();
	my @remove_members  = ();
	my @add_memberdn    = ();
	my @remove_memberdn = ();
	my $addcount        = 0;
	my $removecount     = 0;
	my $notfoundadd     = 0;
	my $notfoundremove  = 0;
	my %hashldapmembers = ();

	my ( $self, $ldap, $data ) = @_;
	$log->debug(
		"Calling CMU::ActiveMQ::processMessageFullSync(self, ldap, data)");

	eval {
		if ( defined $data->{"memberList"} )
		{
			@groupermembers = @{ $data->{"memberList"} };
		}

		my $groupdn = $ldap->getGroupDn( $data->{"name"} );
		my @attrs   = ();
		my $entry   =
		  $ldap->getLdapEntry(
			"(objectClass=" . $ldap->{_groupobjectclass} . ")",
			\@attrs, $groupdn );

		if ( defined $entry ) {
			if ( $CMU::CFG::_CFG{'ldap'}{'env'} eq "AD" ) {
				@ldapmembers = $ldap->getGroupMembers($groupdn);

				my $samaccountnameLdap =
				  $ldap->getSAMAccountNameFromLdapEntry($entry);
				my $samaccountnameGrouper =
				  $ldap->getSAMAccountNameFromGroupName( $data->{"name"} );

				if ( $samaccountnameGrouper ne $samaccountnameLdap ) {
					$ldap->updateSAMAccountName( $groupdn,
						$samaccountnameGrouper );
				}
			}
			else {
				@ldapmembers = $ldap->getGroupMembers($entry);
			}

			%hashldapmembers =
			  CMU::Util::covertMemberDNListToMembersUidHash(
				$ldap->getLdapTargetName(), @ldapmembers );

			@ldapmembers =
			  CMU::Util::covertMemberDNListToMembersUidList(
				$ldap->getLdapTargetName(), @ldapmembers );

			@add_members =
			  CMU::Util::arrayMinus( \@groupermembers, \@ldapmembers );

			foreach (@add_members) {
				my $memberdn = $ldap->getMemberDn($_);
				if ( defined $memberdn ) {
					$addcount++;
					push( @add_memberdn, $memberdn );
				}
				else {
					$notfoundadd++;
				}
			}

			@remove_members =
			  CMU::Util::arrayMinus( \@ldapmembers, \@groupermembers );

			foreach (@remove_members) {
				my $memberdn = $hashldapmembers{$_};
				if ( defined $memberdn ) {
					$removecount++;
					push( @remove_memberdn, $memberdn );
				}
			}

			if (@add_memberdn) {
				$ldap->bulkGroupMemberAdd( \@add_memberdn, $groupdn );
			}

			if (@remove_memberdn) {
				$ldap->bulkGroupMemberRemove( \@remove_memberdn, $groupdn );
			}
		}
		else {
			$ldap->createGroup( $groupdn, $data->{"description"} );

			foreach (@groupermembers) {
				my $memberdn = $ldap->getMemberDn($_);
				if ( defined $memberdn ) {
					push( @add_memberdn, $memberdn );
					$addcount++;
				}
				else {
					$notfoundadd++;
				}

				if ( @add_memberdn && $#add_memberdn == 1000 ) {
					$ldap->bulkGroupMemberAdd( \@add_memberdn, $groupdn );
					undef(@add_memberdn);
				}
			}

			if (@add_memberdn) {
				$ldap->bulkGroupMemberAdd( \@add_memberdn, $groupdn );
			}
		}

		$log->info( "Grouper members count: "
			  . scalar @groupermembers . " for "
			  . $data->{'name'} );
		$log->info(
			"LDAP members count: " . scalar @ldapmembers . " for " . $groupdn );
		$log->info(
			"Add members count: " . $addcount . " for " . $data->{'name'} );
		$log->info( "Add members not found count: "
			  . $notfoundadd . " for "
			  . $data->{'name'} );
		$log->info( "Remove members count: "
			  . $removecount . " for "
			  . $data->{'name'} );
		$log->info( "Fullsync completed successfully for " . $data->{'name'} );

	};
	if ($@) {
		die();
	}
}

sub DESTROY {
	my ($self) = @_;
	$log->debug("Calling CMU::ActiveMQ::DESTROY(self)");

	if ( defined $self->{_stomp} ) {
		$self->{_stomp}->disconnect();
		undef $self->{_stomp};
	}
}

1;
