#Copyright 2014 Carnegie Mellon University
#All rights reserved.

#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

#1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

#2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

#3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package CMU::Stats;
use strict;
use warnings;

my $log = Log::Log4perl->get_logger("CMU.STATS");

my %_data = (
	'amq_num_messages'  => 0,
	'amq_num_users'     => 0,
	'ldap_num_adds'     => 0,
	'ldap_num_modify'   => 0,
	'ldap_num_deletes'  => 0,
	'ldap_num_searches' => 0,
	'start_time'        => 0,
	'end_time'          => 0,
);

sub incrementStat {
	my ($key) = @_;
	$log->debug("Calling CMU::Stats::incrementStat( $key )");

	my $val = $_data{$key};
	$val++;
	$_data{$key} = $val;

}

sub initializeStats {
	$log->debug("Calling CMU::Stats::initializeStats()");

	$_data{'amq_num_messages'}  = 0;
	$_data{'amq_num_groups'}    = 0;
	$_data{'amq_num_users'}     = 0;
	$_data{'ldap_num_adds'}     = 0;
	$_data{'ldap_num_modify'}   = 0;
	$_data{'ldap_num_deletes'}  = 0;
	$_data{'ldap_num_searches'} = 0;
	$_data{'start_time'}        = 0;
	$_data{'end_time'}          = 0;

}

sub updateStat {
	my ( $key, $val ) = @_;
	$log->debug("Calling CMU::Stats::updateStat( $key, $val)");
	$_data{$key} = $val;
}

sub addStat {
	my ( $key, $val ) = @_;
	$log->debug("Calling CMU::Stats::addStat( $key, $val)");
	$_data{$key} = $_data{$key} + $val;
}

sub writeStats {
	$log->debug("Calling CMU::Stats::writeStats() ");

	my $total_elapsed_time = $_data{'end_time'} - $_data{'start_time'};

	my $amq_messages_per_sec = $_data{'amq_num_messages'} / $total_elapsed_time;

	my $ldap_operations_per_sec =
	  ( $_data{'ldap_num_adds'} + $_data{'ldap_num_modify'} +
		  $_data{'ldap_num_deletes'} + $_data{'ldap_num_searches'} ) /
	  $total_elapsed_time;

	$log->info( "LDAP Add|Modify|Delete|Search| "
		  . $_data{'ldap_num_adds'} . "|"
		  . $_data{'ldap_num_modify'} . "|"
		  . $_data{'ldap_num_deletes'} . "|"
		  . $_data{'ldap_num_searches'} );
	$log->info( "AMQ Messages|Users "
		  . $_data{'amq_num_messages'} . "|"
		  . $_data{'amq_num_users'} );
	$log->info( "Operations per second Messages|Ldap "
		  . sprintf( "%.2f", $amq_messages_per_sec ) . "|"
		  . sprintf( "%.2f", $ldap_operations_per_sec ) );
	$log->info( "Total time in minutes: "
		  . sprintf( "%.2f", $total_elapsed_time / 60 ) );

}

1;
