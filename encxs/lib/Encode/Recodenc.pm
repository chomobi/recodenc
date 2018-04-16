package Encode::Recodenc;
################################################################################
# Recodenc
# Copyright © 2016-2018 terqüéz <gz0@ro.ru>
#
# This file is part of Recodenc.
#
# Recodenc is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
use v5.18;
use vars qw($VERSION);
use Encode;
use XSLoader;

*VERSION = \'0.0.1';

XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

Encode::Recodenc - encodings module for Recodenc

=head1 SYNOPSIS

    use Encode qw(encode);
    use Encode::Recodenc;
    $data = encode('cp1252a', $data);
    $data = encode('cp1252b', $data);
    $data = encode('cp1252c', $data);

=head1 SEE ALSO

L<Encode>, L<Recodenc>

=cut
