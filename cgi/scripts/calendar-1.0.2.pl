#!/usr/bin/perl

######################################################################
# Programmer: Al Nguyen
#
# At the command prompt do "perldoc [name of this program] to see
# user documentation.
######################################################################

##############################
# Include these libraries.
##############################

use strict;
use CGI;
$CGI::POST_MAX = 1024 * 100; #100K max post
$CGI::DISABLE_UPLOADS = 1;
use CGI::Carp qw( fatalsToBrowser );
use Data::Dumper;

my $VERSION = 1.0.2;

#################################################
# Main function.  Main logic of program.
#################################################

main();

sub main {

my %form = form2hash();

$form{dtype} = untaint( $form{dtype}, 'begin|end', qq(Invalid date type parameter) );

$form{appID} = untaint( $form{appID}, '\w+', qq(Invalid appID parameter) ) if ! $form{curMonth};

$form{date} = untaint( $form{date}, '\d\d\d\d-\d\d-\d\d', qq(Invalid date parameter) ) if $form{date};

$form{curMonth} = untaint( $form{curMonth}, '\d+', qq(Invalid month parameter) ) if $form{curMonth};

$form{year} = untaint( $form{year}, '\d\d\d\d', qq(Invalid year parameter) ) if $form{year};
	
my $q = new CGI;

	if ( ! $q->param('date') ) {

	( $q->param('dtype') eq 'begin' ) ? showCalendar( 'begin', 0, $form{curMonth}, $form{appID}, $form{year} ) : showCalendar( 'end', 0, $form{curMonth}, $form{appID}, $form{year} );
	
	}

date2cookie( $form{date}, $form{dtype}, $form{appID} );

confDateSelected( $form{date} );

}

###########################################################
# Write the date selected to a session cookie.
###########################################################

sub date2cookie {
	
my( $date, $type, $appID ) = @_;

my $q = new CGI;

my $name = ( $type eq 'begin' ) ? "beginDate-$appID" : "endDate-$appID";

my $c = $q->cookie(

-name => $name,

-value => $date,

);

print $q->header( -cookie => $c );

return( 1 );	
	
}

######################################################################
# Read the date cookie to confirm that it was set properly.
# This function is useful for debugging.
######################################################################

sub readDateCookie {

my( $cookieName ) = @_;

my $q = new CGI;

my $c = $q->cookie( $cookieName );

return( $c );

}

###########################################################
# Show a calendar displaying the current month.
###########################################################

sub showCalendar {

my( $type, $dont_send_type_flag, $current_month, $appID, $year ) = @_;

my( $curYear, $curMonth, $curDay ) = get_system_date();

my $current_date = "$curYear-$curMonth-$curDay";

$current_month = $curMonth if ! $current_month;

$current_month =~ s/^0//;

$curDay =~ s/^0//;

my $whichYear = {

'2005' => \&getCalendar2005,

'2004' => \&getCalendar2004,

'2003' => \&getCalendar2003,

};

$year = $curYear if ! $year;

my $show4year = $whichYear->{ $year };

my $calendar = $show4year->( $current_month, $type, $appID, $year );

print "Content-type: text/html\n\n" if ! $dont_send_type_flag;

my @lines = split( /\n/, $calendar );

	foreach ( @lines ) {
		
	$_ =~ s/\<td\>(\<a href\=\"calendar\.pl\?date\=$current_date\&dtype\=$type\&appID\=$appID\&year\=$year\"\>$curDay\<\/a\>\<\/td\>)/\<td bgcolor\=\"red\"\>$1/;
		
	print $_, "\n";
		
	}

exit;
	
}

###############################################################################
# Put the HTML form input data into a hash.  Returns a hash of form elements
# in key/value pairs.
###############################################################################

sub form2hash {

my $q = new CGI;

my( $name, $value, %form );

	foreach $name ( $q->param() ) {

	$value = $q->param( $name );

	$form{$name} = $value;

	}

return( %form );

}

############################################################################
# Untaint the HTML form input data.  Value is the form value.  Pattern is
# a regular expression.  Returns whatever matches the regular expression.
############################################################################

sub untaint {

my( $value, $pattern, $error_message ) = @_;

( $value =~ m|($pattern)| ) ? return( $1 ) : errorMes( $error_message );

}

##################################################################################
# Output data structures for debugging if necessary.  $data is a reference to
# some kind of data structure.
##################################################################################

sub dumpData {

my( $data ) = @_;

my $data_as_string = Dumper( $data );

my $html = '<br />';

$data_as_string =~ s|\n|$html|sg;

my $q = new CGI;

print $q->header( -type => 'text/html', -expires => 'now' );

print <<heredoc;

<html>

<head><title>Data Dump</title></head>

<body>

<p>&nbsp;</p>

<p align="center"><b>$data_as_string</b></p>

</body>

</html>

heredoc

exit;
	
}

################################################
# Display an error message page if necessary.
################################################

sub errorMes {

my( $message ) = @_;

print "Content-type: text/html\n\n";

print <<heredoc;

<html><head><title>Error</title></head><body bgcolor="#FFFFFF">

<p>&nbsp;</p>

<p align="center"><b>$message</b></p>

</body></html>

heredoc

exit;

}

######################################################################
# Calculate today's date according to the current host computer.
######################################################################

sub get_system_date {

my( $year, $month, $day ) = ( localtime() )[ 5, 4, 3 ];

$year += 1900;

$month += 1;

$month = 0 . $month if $month < 10;

$day = 0 . $day if $day < 10;

return( $year, $month, $day );

}

####################################################
# Give user confirmation that a date was selected.
####################################################

sub confDateSelected {
	
my( $date ) = @_;

print <<heredoc;

<html><head><title>Date Selected</title></head><body bgcolor="#FFFFFF">

<p>&nbsp;</p>

<p align="center"><font size="3">You selected:</font></p>

<p align="center"><font size="5"><b>$date</b></font></p>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

exit;
	
}

####################################################
# Fetch a calendar for the year 2005.
####################################################

sub getCalendar2005 {
	
my( $current_month, $type, $appID, $year ) = @_;

########################
# JANUARY
########################

my $jan = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=12&appID=$appID&year=2004"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>January 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=2&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-01-01&dtype=$type&appID=$appID&year=$year">1</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-01-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-01-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-01-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-01-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-01-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-01-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-01-08&dtype=$type&appID=$appID&year=$year">8</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-01-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-01-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-01-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-01-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-01-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-01-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-01-15&dtype=$type&appID=$appID&year=$year">15</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-01-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-01-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-01-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-01-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-01-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-01-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-01-22&dtype=$type&appID=$appID&year=$year">22</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-01-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-01-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-01-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-01-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-01-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-01-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-01-29&dtype=$type&appID=$appID&year=$year">29</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-01-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2005-01-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# FEBRUARY
########################

my $feb = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=1&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>February 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=3&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-02-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-02-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-02-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-02-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-02-05&dtype=$type&appID=$appID&year=$year">5</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-02-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-02-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-02-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-02-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-02-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-02-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-02-12&dtype=$type&appID=$appID&year=$year">12</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-02-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-02-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-02-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-02-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-02-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-02-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-02-19&dtype=$type&appID=$appID&year=$year">19</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-02-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-02-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-02-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-02-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-02-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-02-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-02-26&dtype=$type&appID=$appID&year=$year">26</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-02-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-02-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# MARCH
########################

my $mar = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=2&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>March 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=4&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-03-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-03-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-03-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-03-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-03-05&dtype=$type&appID=$appID&year=$year">5</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-03-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-03-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-03-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-03-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-03-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-03-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-03-12&dtype=$type&appID=$appID&year=$year">12</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-03-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-03-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-03-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-03-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-03-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-03-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-03-19&dtype=$type&appID=$appID&year=$year">19</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-03-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-03-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-03-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-03-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-03-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-03-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-03-26&dtype=$type&appID=$appID&year=$year">26</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-03-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-03-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-03-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-03-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2005-03-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# APRIL
########################

my $apr = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=3&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>April 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=5&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-04-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-04-02&dtype=$type&appID=$appID&year=$year">2</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-04-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-04-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-04-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-04-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-04-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-04-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-04-09&dtype=$type&appID=$appID&year=$year">9</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-04-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-04-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-04-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-04-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-04-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-04-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-04-16&dtype=$type&appID=$appID&year=$year">16</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-04-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-04-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-04-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-04-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-04-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-04-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-04-23&dtype=$type&appID=$appID&year=$year">23</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-04-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-04-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-04-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-04-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-04-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-04-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-04-30&dtype=$type&appID=$appID&year=$year">30</a></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# MAY
########################

my $may = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=4&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>May 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=6&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-05-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-05-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-05-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-05-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-05-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-05-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-05-07&dtype=$type&appID=$appID&year=$year">7</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-05-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-05-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-05-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-05-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-05-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-05-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-05-14&dtype=$type&appID=$appID&year=$year">14</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-05-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-05-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-05-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-05-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-05-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-05-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-05-21&dtype=$type&appID=$appID&year=$year">21</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-05-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-05-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-05-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-05-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-05-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-05-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-05-28&dtype=$type&appID=$appID&year=$year">28</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-05-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-05-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2005-05-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# JUNE
########################

my $jun = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=5&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>June 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=7&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-06-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-06-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-06-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-06-04&dtype=$type&appID=$appID&year=$year">4</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-06-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-06-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-06-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-06-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-06-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-06-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-06-11&dtype=$type&appID=$appID&year=$year">11</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-06-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-06-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-06-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-06-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-06-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-06-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-06-18&dtype=$type&appID=$appID&year=$year">18</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-06-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-06-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-06-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-06-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-06-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-06-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-06-25&dtype=$type&appID=$appID&year=$year">25</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-06-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-06-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-06-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-06-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-06-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# JULY
########################

my $jul = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=6&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>July 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=8&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-07-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-07-02&dtype=$type&appID=$appID&year=$year">2</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-07-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-07-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-07-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-07-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-07-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-07-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-07-09&dtype=$type&appID=$appID&year=$year">9</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-07-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-07-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-07-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-07-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-07-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-07-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-07-16&dtype=$type&appID=$appID&year=$year">16</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-07-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-07-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-07-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-07-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-07-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-07-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-07-23&dtype=$type&appID=$appID&year=$year">23</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-07-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-07-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-07-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-07-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-07-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-07-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-07-30&dtype=$type&appID=$appID&year=$year">30</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-07-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# AUGUST
########################

my $aug = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=7&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>August 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=9&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td><a href="calendar.pl?date=2005-08-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-08-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-08-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-08-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-08-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-08-06&dtype=$type&appID=$appID&year=$year">6</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-08-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-08-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-08-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-08-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-08-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-08-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-08-13&dtype=$type&appID=$appID&year=$year">13</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-08-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-08-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-08-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-08-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-08-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-08-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-08-20&dtype=$type&appID=$appID&year=$year">20</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-08-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-08-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-08-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-08-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-08-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-08-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-08-27&dtype=$type&appID=$appID&year=$year">27</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-08-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-08-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-08-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2005-08-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# SEPTEMBER
########################

my $sep = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=8&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>September 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=10&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-09-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-09-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-09-03&dtype=$type&appID=$appID&year=$year">3</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-09-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-09-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-09-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-09-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-09-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-09-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-09-10&dtype=$type&appID=$appID&year=$year">10</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-09-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-09-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-09-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-09-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-09-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-09-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-09-17&dtype=$type&appID=$appID&year=$year">17</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-09-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-09-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-09-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-09-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-09-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-09-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-09-24&dtype=$type&appID=$appID&year=$year">24</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-09-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-09-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-09-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-09-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-09-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-09-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# OCTOBER
########################

my $oct = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=9&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>October 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=11&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-10-01&dtype=$type&appID=$appID&year=$year">1</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-10-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-10-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-10-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-10-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-10-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-10-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-10-08&dtype=$type&appID=$appID&year=$year">8</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-10-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-10-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-10-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-10-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-10-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-10-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-10-15&dtype=$type&appID=$appID&year=$year">15</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-10-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-10-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-10-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-10-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-10-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-10-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-10-22&dtype=$type&appID=$appID&year=$year">22</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-10-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-10-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-10-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-10-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-10-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-10-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-10-29&dtype=$type&appID=$appID&year=$year">29</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-10-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2005-10-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# NOVEMBER
########################

my $nov = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=10&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>November 2005</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=12&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-11-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-11-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-11-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2005-11-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-11-05&dtype=$type&appID=$appID&year=$year">5</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-11-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-11-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-11-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-11-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-11-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2005-11-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-11-12&dtype=$type&appID=$appID&year=$year">12</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-11-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-11-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-11-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-11-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-11-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2005-11-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-11-19&dtype=$type&appID=$appID&year=$year">19</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-11-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-11-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-11-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-11-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-11-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2005-11-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-11-26&dtype=$type&appID=$appID&year=$year">26</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-11-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-11-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-11-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-11-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# DECEMBER
########################

my $dec = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=11&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>December 2005</b>&nbsp;&nbsp;
<!--<a href="calendar.pl?dtype=$type&curMonth=12&appID=$appID&year=$year"><b>&gt;&gt;</b></a>-->
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2005-12-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2005-12-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2005-12-03&dtype=$type&appID=$appID&year=$year">3</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-12-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2005-12-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2005-12-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2005-12-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2005-12-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2005-12-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2005-12-10&dtype=$type&appID=$appID&year=$year">10</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-12-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2005-12-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2005-12-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2005-12-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2005-12-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2005-12-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2005-12-17&dtype=$type&appID=$appID&year=$year">17</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-12-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2005-12-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2005-12-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2005-12-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2005-12-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2005-12-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2005-12-24&dtype=$type&appID=$appID&year=$year">24</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2005-12-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2005-12-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2005-12-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2005-12-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2005-12-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2005-12-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2005-12-31&dtype=$type&appID=$appID&year=$year">31</a></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

my $months = {
	
'1' => $jan,

'2' => $feb,

'3' => $mar,

'4' => $apr,

'5' => $may,

'6' => $jun,

'7' => $jul,

'8' => $aug,

'9' => $sep,

'10' => $oct,

'11' => $nov,

'12' => $dec,
	
};

return( $months->{ $current_month } );
	
}

####################################################
# Fetch a calendar for the year 2004.
####################################################

sub getCalendar2004 {
	
my( $current_month, $type, $appID, $year ) = @_;

########################
# JANUARY
########################

my $jan = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=12&appID=$appID&year=2003"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>January 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=2&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-01-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-01-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-01-03&dtype=$type&appID=$appID&year=$year">3</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-01-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-01-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-01-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-01-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-01-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-01-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-01-10&dtype=$type&appID=$appID&year=$year">10</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-01-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-01-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-01-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-01-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-01-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-01-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-01-17&dtype=$type&appID=$appID&year=$year">17</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-01-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-01-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-01-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-01-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-01-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-01-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-01-24&dtype=$type&appID=$appID&year=$year">24</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-01-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-01-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-01-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-01-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-01-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-01-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2004-01-31&dtype=$type&appID=$appID&year=$year">31</a></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# FEBRUARY
########################

my $feb = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=1&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>February 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=3&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-02-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-02-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-02-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-02-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-02-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-02-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-02-07&dtype=$type&appID=$appID&year=$year">7</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-02-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-02-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-02-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-02-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-02-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-02-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-02-14&dtype=$type&appID=$appID&year=$year">14</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-02-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-02-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-02-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-02-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-02-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-02-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-02-21&dtype=$type&appID=$appID&year=$year">21</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-02-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-02-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-02-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-02-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-02-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-02-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-02-28&dtype=$type&appID=$appID&year=$year">28</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-02-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# MARCH
########################

my $mar = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=2&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>March 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=4&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td><a href="calendar.pl?date=2004-03-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-03-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-03-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-03-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-03-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-03-06&dtype=$type&appID=$appID&year=$year">6</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-03-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-03-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-03-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-03-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-03-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-03-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-03-13&dtype=$type&appID=$appID&year=$year">13</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-03-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-03-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-03-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-03-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-03-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-03-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-03-20&dtype=$type&appID=$appID&year=$year">20</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-03-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-03-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-03-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-03-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-03-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-03-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-03-27&dtype=$type&appID=$appID&year=$year">27</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-03-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-03-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-03-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2004-03-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# APRIL
########################

my $apr = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=3&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>April 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=5&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-04-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-04-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-04-03&dtype=$type&appID=$appID&year=$year">3</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-04-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-04-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-04-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-04-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-04-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-04-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-04-10&dtype=$type&appID=$appID&year=$year">10</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-04-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-04-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-04-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-04-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-04-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-04-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-04-17&dtype=$type&appID=$appID&year=$year">17</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-04-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-04-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-04-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-04-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-04-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-04-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-04-24&dtype=$type&appID=$appID&year=$year">24</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-04-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-04-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-04-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-04-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-04-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-04-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# MAY
########################

my $may = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=4&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>May 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=6&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-05-01&dtype=$type&appID=$appID&year=$year">1</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-05-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-05-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-05-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-05-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-05-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-05-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-05-08&dtype=$type&appID=$appID&year=$year">8</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-05-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-05-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-05-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-05-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-05-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-05-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-05-15&dtype=$type&appID=$appID&year=$year">15</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-05-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-05-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-05-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-05-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-05-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-05-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-05-22&dtype=$type&appID=$appID&year=$year">22</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-05-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-05-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-05-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-05-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-05-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-05-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-05-29&dtype=$type&appID=$appID&year=$year">29</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-05-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2004-05-31&dtype=$type&appID=$appID&year=$year">31</a></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# JUNE
########################

my $jun = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=5&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>June 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=7&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-06-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-06-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-06-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-06-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-06-05&dtype=$type&appID=$appID&year=$year">5</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-06-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-06-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-06-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-06-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-06-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-06-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-06-12&dtype=$type&appID=$appID&year=$year">12</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-06-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-06-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-06-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-06-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-06-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-06-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-06-19&dtype=$type&appID=$appID&year=$year">19</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-06-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-06-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-06-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-06-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-06-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-06-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-06-26&dtype=$type&appID=$appID&year=$year">26</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-06-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-06-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-06-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-06-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# JULY
########################

my $jul = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=6&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>July 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=8&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-07-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-07-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-07-03&dtype=$type&appID=$appID&year=$year">3</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-07-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-07-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-07-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-07-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-07-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-07-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-07-10&dtype=$type&appID=$appID&year=$year">10</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-07-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-07-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-07-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-07-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-07-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-07-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-07-17&dtype=$type&appID=$appID&year=$year">17</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-07-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-07-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-07-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-07-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-07-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-07-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-07-24&dtype=$type&appID=$appID&year=$year">24</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-07-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-07-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-07-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-07-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-07-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-07-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2004-07-31&dtype=$type&appID=$appID&year=$year">31</a></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# AUGUST
########################

my $aug = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=7&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>August 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=9&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-08-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-08-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-08-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-08-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-08-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-08-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-08-07&dtype=$type&appID=$appID&year=$year">7</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-08-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-08-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-08-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-08-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-08-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-08-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-08-14&dtype=$type&appID=$appID&year=$year">14</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-08-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-08-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-08-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-08-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-08-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-08-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-08-21&dtype=$type&appID=$appID&year=$year">21</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-08-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-08-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-08-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-08-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-08-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-08-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-08-28&dtype=$type&appID=$appID&year=$year">28</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-08-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-08-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2004-08-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# SEPTEMBER
########################

my $sep = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=8&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>September 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=10&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-09-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-09-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-09-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-09-04&dtype=$type&appID=$appID&year=$year">4</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-09-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-09-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-09-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-09-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-09-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-09-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-09-11&dtype=$type&appID=$appID&year=$year">11</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-09-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-09-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-09-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-09-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-09-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-09-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-09-18&dtype=$type&appID=$appID&year=$year">18</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-09-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-09-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-09-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-09-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-09-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-09-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-09-25&dtype=$type&appID=$appID&year=$year">25</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-09-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-09-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-09-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-09-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-09-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# OCTOBER
########################

my $oct = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=9&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>October 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=11&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-10-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-10-02&dtype=$type&appID=$appID&year=$year">2</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-10-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-10-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-10-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-10-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-10-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-10-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-10-09&dtype=$type&appID=$appID&year=$year">9</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-10-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-10-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-10-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-10-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-10-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-10-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-10-16&dtype=$type&appID=$appID&year=$year">16</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-10-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-10-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-10-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-10-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-10-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-10-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-10-23&dtype=$type&appID=$appID&year=$year">23</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-10-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-10-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-10-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-10-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-10-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-10-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-10-30&dtype=$type&appID=$appID&year=$year">30</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-10-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# NOVEMBER
########################

my $nov = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=10&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>November 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=12&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td><a href="calendar.pl?date=2004-11-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-11-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-11-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-11-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2004-11-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-11-06&dtype=$type&appID=$appID&year=$year">6</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-11-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-11-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-11-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-11-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-11-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2004-11-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-11-13&dtype=$type&appID=$appID&year=$year">13</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-11-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-11-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-11-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-11-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-11-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2004-11-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-11-20&dtype=$type&appID=$appID&year=$year">20</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-11-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-11-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-11-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-11-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-11-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2004-11-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-11-27&dtype=$type&appID=$appID&year=$year">27</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-11-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-11-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-11-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# DECEMBER
########################

my $dec = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=11&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>December 2004</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=1&appID=$appID&year=2005"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2004-12-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2004-12-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2004-12-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2004-12-04&dtype=$type&appID=$appID&year=$year">4</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-12-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2004-12-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2004-12-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2004-12-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2004-12-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2004-12-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2004-12-11&dtype=$type&appID=$appID&year=$year">11</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-12-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2004-12-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2004-12-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2004-12-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2004-12-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2004-12-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2004-12-18&dtype=$type&appID=$appID&year=$year">18</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-12-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2004-12-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2004-12-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2004-12-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2004-12-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2004-12-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2004-12-25&dtype=$type&appID=$appID&year=$year">25</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2004-12-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2004-12-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2004-12-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2004-12-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2004-12-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2004-12-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

my $months = {
	
'1' => $jan,

'2' => $feb,

'3' => $mar,

'4' => $apr,

'5' => $may,

'6' => $jun,

'7' => $jul,

'8' => $aug,

'9' => $sep,

'10' => $oct,

'11' => $nov,

'12' => $dec,
	
};

return( $months->{ $current_month } );
	
}

####################################################
# Fetch a calendar for the year 2003.
####################################################

sub getCalendar2003 {
	
my( $current_month, $type, $appID, $year ) = @_;

########################
# JANUARY
########################

my $jan = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<!--<a href="calendar.pl?dtype=$type&curMonth=12&appID=$appID&year=$year"><b>&lt;&lt;</b></a>-->
&nbsp;&nbsp;<b>January 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=2&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-01-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-01-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-01-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-01-04&dtype=$type&appID=$appID&year=$year">4</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-01-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-01-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-01-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-01-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-01-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-01-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-01-11&dtype=$type&appID=$appID&year=$year">11</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-01-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-01-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-01-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-01-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-01-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-01-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-01-18&dtype=$type&appID=$appID&year=$year">18</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-01-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-01-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-01-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-01-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-01-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-01-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-01-25&dtype=$type&appID=$appID&year=$year">25</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-01-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-01-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-01-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-01-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-01-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2003-01-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# FEBRUARY
########################

my $feb = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=1&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>February 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=3&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-02-01&dtype=$type&appID=$appID&year=$year">1</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-02-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-02-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-02-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-02-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-02-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-02-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-02-08&dtype=$type&appID=$appID&year=$year">8</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-02-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-02-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-02-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-02-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-02-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-02-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-02-15&dtype=$type&appID=$appID&year=$year">15</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-02-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-02-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-02-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-02-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-02-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-02-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-02-22&dtype=$type&appID=$appID&year=$year">22</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-02-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-02-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-02-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-02-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-02-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-02-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# MARCH
########################

my $mar = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=2&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>March 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=4&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-03-01&dtype=$type&appID=$appID&year=$year">1</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-03-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-03-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-03-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-03-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-03-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-03-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-03-08&dtype=$type&appID=$appID&year=$year">8</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-03-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-03-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-03-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-03-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-03-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-03-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-03-15&dtype=$type&appID=$appID&year=$year">15</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-03-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-03-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-03-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-03-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-03-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-03-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-03-22&dtype=$type&appID=$appID&year=$year">22</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-03-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-03-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-03-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-03-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-03-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-03-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-03-29&dtype=$type&appID=$appID&year=$year">29</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-03-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2003-03-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# APRIL
########################

my $apr = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=3&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>April 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=5&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-04-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-04-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-04-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-04-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-04-05&dtype=$type&appID=$appID&year=$year">5</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-04-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-04-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-04-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-04-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-04-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-04-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-04-12&dtype=$type&appID=$appID&year=$year">12</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-04-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-04-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-04-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-04-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-04-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-04-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-04-19&dtype=$type&appID=$appID&year=$year">19</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-04-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-04-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-04-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-04-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-04-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-04-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-04-26&dtype=$type&appID=$appID&year=$year">26</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-04-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-04-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-04-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-04-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# MAY
########################

my $may = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=4&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>May 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=6&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-05-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-05-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-05-03&dtype=$type&appID=$appID&year=$year">3</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-05-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-05-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-05-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-05-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-05-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-05-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-05-10&dtype=$type&appID=$appID&year=$year">10</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-05-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-05-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-05-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-05-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-05-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-05-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-05-17&dtype=$type&appID=$appID&year=$year">17</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-05-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-05-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-05-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-05-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-05-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-05-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-05-24&dtype=$type&appID=$appID&year=$year">24</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-05-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-05-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-05-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-05-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-05-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-05-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2003-05-31&dtype=$type&appID=$appID&year=$year">31</a></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# JUNE
########################

my $jun = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=5&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>June 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=7&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-06-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-06-02&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-06-03&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-06-04&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-06-05&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-06-06&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-06-07&dtype=$type&appID=$appID&year=$year">5</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-06-08&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-06-09&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-06-10&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-06-11&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-06-12&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-06-13&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-06-14&dtype=$type&appID=$appID&year=$year">12</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-06-15&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-06-16&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-06-17&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-06-18&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-06-19&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-06-20&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-06-21&dtype=$type&appID=$appID&year=$year">19</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-06-22&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-06-23&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-06-24&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-06-25&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-06-26&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-06-27&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-06-28&dtype=$type&appID=$appID&year=$year">26</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-06-29&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-06-30&dtype=$type&appID=$appID&year=$year">28</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# JULY
########################

my $jul = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=6&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>July 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=8&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-07-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-07-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-07-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-07-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-07-05&dtype=$type&appID=$appID&year=$year">5</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-07-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-07-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-07-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-07-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-07-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-07-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-07-12&dtype=$type&appID=$appID&year=$year">12</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-07-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-07-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-07-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-07-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-07-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-07-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-07-19&dtype=$type&appID=$appID&year=$year">19</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-07-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-07-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-07-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-07-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-07-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-07-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-07-26&dtype=$type&appID=$appID&year=$year">26</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-07-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-07-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-07-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-07-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2003-07-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# AUGUST
########################

my $aug = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=7&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>August 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=9&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-08-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-08-02&dtype=$type&appID=$appID&year=$year">2</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-08-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-08-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-08-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-08-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-08-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-08-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-08-09&dtype=$type&appID=$appID&year=$year">9</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-08-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-08-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-08-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-08-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-08-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-08-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-08-16&dtype=$type&appID=$appID&year=$year">16</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-08-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-08-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-08-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-08-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-08-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-08-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-08-23&dtype=$type&appID=$appID&year=$year">23</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-08-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-08-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-08-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-08-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-08-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-08-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-08-30&dtype=$type&appID=$appID&year=$year">30</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-08-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# SEPTEMBER
########################

my $sep = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=8&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>September 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=10&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td><a href="calendar.pl?date=2003-09-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-09-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-09-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-09-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-09-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-09-06&dtype=$type&appID=$appID&year=$year">6</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-09-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-09-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-09-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-09-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-09-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-09-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-09-13&dtype=$type&appID=$appID&year=$year">13</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-09-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-09-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-09-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-09-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-09-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-09-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-09-20&dtype=$type&appID=$appID&year=$year">20</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-09-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-09-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-09-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-09-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-09-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-09-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-09-27&dtype=$type&appID=$appID&year=$year">27</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-09-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-09-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-09-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# OCTOBER
########################

my $oct = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=9&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>October 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=11&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-10-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-10-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-10-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-10-04&dtype=$type&appID=$appID&year=$year">4</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-10-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-10-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-10-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-10-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-10-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-10-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-10-11&dtype=$type&appID=$appID&year=$year">11</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-10-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-10-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-10-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-10-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-10-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-10-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-10-18&dtype=$type&appID=$appID&year=$year">18</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-10-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-10-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-10-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-10-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-10-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-10-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-10-25&dtype=$type&appID=$appID&year=$year">25</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-10-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-10-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-10-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-10-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-10-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2003-10-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-10-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# NOVEMBER
########################

my $nov = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=10&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>November 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=12&appID=$appID&year=$year"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td><a href="calendar.pl?date=2003-11-01&dtype=$type&appID=$appID&year=$year">1</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-11-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-11-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-11-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-11-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-11-06&dtype=$type&appID=$appID&year=$year">6</a></td>
<td><a href="calendar.pl?date=2003-11-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-11-08&dtype=$type&appID=$appID&year=$year">8</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-11-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-11-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-11-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-11-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-11-13&dtype=$type&appID=$appID&year=$year">13</a></td>
<td><a href="calendar.pl?date=2003-11-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-11-15&dtype=$type&appID=$appID&year=$year">15</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-11-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-11-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-11-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-11-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-11-20&dtype=$type&appID=$appID&year=$year">20</a></td>
<td><a href="calendar.pl?date=2003-11-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-11-22&dtype=$type&appID=$appID&year=$year">22</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-11-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-11-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-11-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-11-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-11-27&dtype=$type&appID=$appID&year=$year">27</a></td>
<td><a href="calendar.pl?date=2003-11-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-11-29&dtype=$type&appID=$appID&year=$year">29</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-11-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

########################
# DECEMBER
########################

my $dec = <<heredoc;

<html><head><title>Select a Date</title></head><body bgcolor="#FFFFFF">

<p align="center">
<a href="calendar.pl?dtype=$type&curMonth=11&appID=$appID&year=$year"><b>&lt;&lt;</b></a>
&nbsp;&nbsp;<b>December 2003</b>&nbsp;&nbsp;
<a href="calendar.pl?dtype=$type&curMonth=1&appID=$appID&year=2004"><b>&gt;&gt;</b></a>
</p>

<div align="center">

<table border="0">

<tr align="center"><td><b>S</b></td><td><b>M</b></td><td><b>T</b></td><td><b>W</b></td><td><b>T</b></td><td><b>F</b></td><td><b>S</b></td></tr>

<tr align="center">
<td></td>
<td><a href="calendar.pl?date=2003-12-01&dtype=$type&appID=$appID&year=$year">1</a></td>
<td><a href="calendar.pl?date=2003-12-02&dtype=$type&appID=$appID&year=$year">2</a></td>
<td><a href="calendar.pl?date=2003-12-03&dtype=$type&appID=$appID&year=$year">3</a></td>
<td><a href="calendar.pl?date=2003-12-04&dtype=$type&appID=$appID&year=$year">4</a></td>
<td><a href="calendar.pl?date=2003-12-05&dtype=$type&appID=$appID&year=$year">5</a></td>
<td><a href="calendar.pl?date=2003-12-06&dtype=$type&appID=$appID&year=$year">6</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-12-07&dtype=$type&appID=$appID&year=$year">7</a></td>
<td><a href="calendar.pl?date=2003-12-08&dtype=$type&appID=$appID&year=$year">8</a></td>
<td><a href="calendar.pl?date=2003-12-09&dtype=$type&appID=$appID&year=$year">9</a></td>
<td><a href="calendar.pl?date=2003-12-10&dtype=$type&appID=$appID&year=$year">10</a></td>
<td><a href="calendar.pl?date=2003-12-11&dtype=$type&appID=$appID&year=$year">11</a></td>
<td><a href="calendar.pl?date=2003-12-12&dtype=$type&appID=$appID&year=$year">12</a></td>
<td><a href="calendar.pl?date=2003-12-13&dtype=$type&appID=$appID&year=$year">13</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-12-14&dtype=$type&appID=$appID&year=$year">14</a></td>
<td><a href="calendar.pl?date=2003-12-15&dtype=$type&appID=$appID&year=$year">15</a></td>
<td><a href="calendar.pl?date=2003-12-16&dtype=$type&appID=$appID&year=$year">16</a></td>
<td><a href="calendar.pl?date=2003-12-17&dtype=$type&appID=$appID&year=$year">17</a></td>
<td><a href="calendar.pl?date=2003-12-18&dtype=$type&appID=$appID&year=$year">18</a></td>
<td><a href="calendar.pl?date=2003-12-19&dtype=$type&appID=$appID&year=$year">19</a></td>
<td><a href="calendar.pl?date=2003-12-20&dtype=$type&appID=$appID&year=$year">20</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-12-21&dtype=$type&appID=$appID&year=$year">21</a></td>
<td><a href="calendar.pl?date=2003-12-22&dtype=$type&appID=$appID&year=$year">22</a></td>
<td><a href="calendar.pl?date=2003-12-23&dtype=$type&appID=$appID&year=$year">23</a></td>
<td><a href="calendar.pl?date=2003-12-24&dtype=$type&appID=$appID&year=$year">24</a></td>
<td><a href="calendar.pl?date=2003-12-25&dtype=$type&appID=$appID&year=$year">25</a></td>
<td><a href="calendar.pl?date=2003-12-26&dtype=$type&appID=$appID&year=$year">26</a></td>
<td><a href="calendar.pl?date=2003-12-27&dtype=$type&appID=$appID&year=$year">27</a></td>
</tr>

<tr align="center">
<td><a href="calendar.pl?date=2003-12-28&dtype=$type&appID=$appID&year=$year">28</a></td>
<td><a href="calendar.pl?date=2003-12-29&dtype=$type&appID=$appID&year=$year">29</a></td>
<td><a href="calendar.pl?date=2003-12-30&dtype=$type&appID=$appID&year=$year">30</a></td>
<td><a href="calendar.pl?date=2003-12-31&dtype=$type&appID=$appID&year=$year">31</a></td>
<td></td>
<td></td>
<td></td>
</tr>

</table>

</div>

<p align="center"><a href="javascript:window.close()"><b>Close Window</b></a></p>

</body></html>

heredoc

my $months = {
	
'1' => $jan,

'2' => $feb,

'3' => $mar,

'4' => $apr,

'5' => $may,

'6' => $jun,

'7' => $jul,

'8' => $aug,

'9' => $sep,

'10' => $oct,

'11' => $nov,

'12' => $dec,
	
};

return( $months->{ $current_month } );
	
}

###########################################################
# This section is for more detailed documentation.
###########################################################

__END__

=head1 NAME

calendar.pl

=head1 DESCRIPTION

This program displays a calendar that allows a user to select a date.  The selected date is written to a session cookie where other programs can access it.  The date is in the format:  yyyy-mm-dd.  The program should be launched within a javascript pop-up window.  It should be called with the query string parameters:  calendar.pl?dtype=begin&appID=onlineCatalog.  The dtype parameter should be 'begin' or 'end' depending on whether it's a beginning date to a range or the end date.  The appID param can be any alpha-numeric string identifying the application that will read the cookie.  This parameter allows more than one application to use the program during a browser session.  If you find this program useful please send me an email at anguyen@cpan.org.  I answer tech support questions at this address as well.

=head1 README

A little calendar that allows users to select a date.  Run it in a pop-up window.  Writes the date selected to a session cookie for any application to read.  Works on Unix and Windows.

=pod OSNAMES

Unix and Windows

=pod SCRIPT CATEGORIES

CGI

=cut
