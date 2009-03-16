package Business::CardInfo;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.02';

subtype 'CardNumber'
  => as 'Int'
   => where { validate($_) };

coerce 'CardNumber'
  => from 'Str'
   => via {
    my $cc = shift;
    $cc =~ s/\s//g;
    return $cc;
   };

no Moose::Util::TypeConstraints;

has 'country' => (
  isa => 'Str',
  is  => 'rw',
  default => 'UK'
  );

has 'number' => (
  isa => 'CardNumber',
  is  => 'rw',
  required => 1,
  coerce => 1,
  trigger => sub { shift->clear_type }
);

has 'type' => (
  isa => 'Str',
  is  => 'rw',
  lazy_build => 1,
);

sub _build_type {
  my $self = shift;
  my $number = $self->number;
  #my @grp = (substr($number,0,1), substr($number,0,4),substr($number,0,6));
  return "Visa Electron" if $self->_search([qw/417500 4917 4913 4508 4844/]);
  return "Visa" if $self->_search([qw/4/]);
  return "MasterCard" if $self->_search([51 .. 55]);
  if($self->country eq 'UK') {
    return "Diners Club" if $self->_search([36]);
    return "MasterCard" if $self->_search([54,55]);
  }
  return "Maestro"
    if $self->_search([qw/5020 5038 6304 6759 6761 4903 4905 4911 4936 564182 633110 6333 5033 5868/]);
  return "Solo" if $self->_search([qw/6334 6767/]);
  return "AMEX" if $self->_search([qw/34 37/]);;
  return "Diners Club" if $self->_search([300 .. 305,2014,2149,46,55]);
  return "Discover" if $self->_search([6011,65]);
  return "JCB" if $self->_search([qw/1800 2131 35/]);
  return "Unknown";
}

sub _search {
  my ($self,$arr) = @_;
  foreach(@{$arr}) {
    return 1 if $self->number =~ /^$_/;
  }
  return 0;
}

sub validate {
  my $number = shift;
  my $num_length = length($number);
  return unless $num_length > 12;
  my ($i, $sum, $weight);
  for ($i = 0; $i < $num_length - 1; $i++) {
    $weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
    $sum += (($weight < 10) ? $weight : ($weight - 9));
  }
  return substr($number, -1) == (10 - $sum % 10) % 10 ? 1 : 0;
}

=head1 NAME

Business::CardInfo - Get/Validate data from credit & debit cards

=head1 SYNOPSIS

  use Business::CardInfo;

  my $card_info = Business::CardInfo->new(number => '4917 3000 0000 0008');
  print $card_info->type, "\n"; # prints Visa Electron

  $card_info->number('5404 0000 0000 0001');
  print $card_info->type, "\n"; # prints MasterCard

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 country

=head2 number

=head2 type

Possible return values are:

  Visa Electron
  Visa
  MasterCard
  Diners Club
  Maestro
  Solo
  AMEX
  Discover
  JCB
  Unknown

=head1 METHODS

=head2 validate

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-cardtype at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-CardInfo>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::CardInfo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-CardInfo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-CardInfo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-CardInfo>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-CardInfo>

=back

=head1 AUTHORS

  purge: Simon Elliott <cpan@browsing.co.uk>

  wreis: Wallace Reis <reis.wallace@gmail.com>

=head1 ACKNOWLEDGEMENTS

  To Airspace Software Ltd <http://www.airspace.co.uk>, for the sponsorship.

=head1 LICENSE

  This library is free software under the same license as perl itself.

=cut

1;