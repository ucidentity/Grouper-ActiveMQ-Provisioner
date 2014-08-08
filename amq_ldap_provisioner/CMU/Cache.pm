#Copyright 2014 Carnegie Mellon University
#All rights reserved.

#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

#1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

#2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

#3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package CMU::Cache;
use strict;
use warnings;

my %_cache;

my $log = Log::Log4perl->get_logger();

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub get {
    my ($self, $key) = @_;
    $log->debug("Calling CMU::Cache::get(self, $key)");
    
    return $self->{_cache}{$key};
}

sub set {
    my ($self, $key, $val) = @_;
    $log->debug("Calling CMU::Cache::set(self, $key, $val)");
      
    $self->{_cache}{$key} = $val;
}

sub delete  {
    my ($self, $key) = @_;
    $log->debug("Calling CMU::Cache::delete(self, $key)");
     
    delete $self->{_cache}{$key};
}

sub purge {
    my $self = shift;
    #$log->debug("Calling CMU::Cache::purge(self)");
      
    for my $key (keys %{$self->{_cache}}) {
        delete $self->{_cache}{$key};
    }
}

sub count {
    my $self = shift;
    $log->debug("Calling CMU::Cache::count(self)");
      
    return 0+keys %{$self->{_cache}};
}

1;