#!/usr/bin/perl

#Libraries
use Net::FTP;
use Getopt::Long;

#Declarations
my $VERSION = '0.1b';

#Prepare usage message
use constant USAGEMSG => "\n
Usage: middleman [options]
Options:
	--in	<servername>	Name of source server
	--out	<servername>	Name of destination server
	--user1 <username>	Username on source server
	--user2 <username>	Username on destination server
	--pass1 <password>	Password on source server
	--pass2 <password>	Password on destination server
	--path1 <path>		Path to files on source server
	--path2 <path>		Path to files on destination server\n";

#Grab all options from command line
if (defined(@ARGV))
        {
        $source_host = $ARGV[0];
        $dest_host = $ARGV[1];
        }
GetOptions ('in:s' => \$source_host,
	    'out:s' => \$dest_host,
	    'user1:s' => \$source_username,
	    'user2:s' => \$dest_username,
	    'pass1:s' => \$source_pass,
	    'pass2:s' => \$dest_pass,
	    'path1:s' => \$source_path,
	    'path2:s' => \$dest_path);

#Prompt user for source and destination server if needed
unless ($source_host)
	{
	print "What is the source server? ";
	$source_host=<STDIN>;chomp $source_host;
	}
unless ($dest_host)
        {
        print "What is the destination server? ";
        $dest_host=<STDIN>;chomp $dest_host;
        }


#Prompt user for source information
unless ($source_username)
	{
	print "What username shall I use on the source server? ";
	$source_username=<STDIN>;chomp $source_username;
	}
unless ($source_pass)
	{
	print "What password shall I use on the source server? ";
	$source_pass=<STDIN>;chomp $source_pass;
	}
unless ($source_path)
	{
	print "What is the source server's path? ";
	$source_path=<STDIN>;chomp $source_path;
	}

#Prompt user for destination information
unless ($dest_username)
{
	print "What username shall I use on the destination server? ";
	$dest_username=<STDIN>;chomp $dest_username;
}
unless ($dest_pass)
{
	print "What password shall I use on the destination server? ";
	$dest_pass=<STDIN>;chomp $dest_pass;
}
unless ($dest_path)
{
	print "What is the destination server's path? ";
	$dest_path=<STDIN>;chomp $dest_path;
}

#Check that all values are properly defined before making connection
die USAGEMSG unless (defined($source_host));
die USAGEMSG unless (defined($source_username));
die USAGEMSG unless (defined($source_pass));
die USAGEMSG unless (defined($source_path));
die USAGEMSG unless (defined($dest_host));
die USAGEMSG unless (defined($dest_username));
die USAGEMSG unless (defined($dest_pass));
die USAGEMSG unless (defined($dest_path));

#Make connection to source server
$source = Net::FTP->new($source_host);
$source->login($source_username, $source_pass) or die $source->message;
$source->cwd($source_path) or die $source->message;
$source->binary or die $source->message;

#Make connection to destination server
$dest = Net::FTP->new($dest_host) or die $dest->message;
$dest->login($dest_username, $dest_pass) or die $dest->message;
$dest->cwd($dest_path) or die $dest->message;
$dest->binary or die $source->message;

#Main loop
&grab($source_path);
&end();

#Subfunction to read from source server and copy to destination
sub grab {
($path)=@_;
foreach ($source->ls())
	{
	if (&filetype($_) eq 'd')
		{
		$source->cwd($_) or die $_, ": ", $source->message;
		&grab($_);
		print "// ", $_, " \\\\\n";
		$source->cdup() or die $source->message;
		$dest->cdup() or die $dest->message;
		next();
		}
	print $_, "\n";
	
	
	$source->get($_,$_) or die $source->message;
	$dest->put($_) or die $dest->message;
	unlink($_);
	}
}

#Determine if a file is a regular file or a directory
sub filetype {
($current_file)=@_;
$return_directory = $source->pwd();
$type = "f";
if ($source->cwd($current_file))
	{
	$type = "d";
	&destsync($current_file);
	$source->cwd($return_directory) or die $source->message;
	}
return $type;
}

#Create appropriate directory on destination server to mirror source server
sub destsync{
($directory) = @_;
unless ($dest->cwd($directory))
	{
	$dest->mkdir($directory) or die $directory, ": ", $dest->message;
	$dest->cwd($directory) or die $directory, ": ", $dest->message;
	}
return(0);
}

#Close connections
sub end{
$source->quit;
$dest->quit;
exit (0);
}

#CPAN Information
=head1 NAME
Middleman 0.1b - Transfers files between two FTP servers which do not
support passive transfer

=head1 Author
Christopher Porter, qube@quberoot.com

=head1 Copyright

Distributed under GNU License. May be freely used, copied, and modified for
educational purposes if credit is given to original author and the program
is not used for academic fraud.

=head1 PREREQUISITES

Program has only been tested with Perl 5.0 and higher.
Net::FTP and Getopt modules must be installed.

=head1 DESCRIPTION

This program will automate the transfer of files from one FTP server to another 
in cases where both servers do not support passive mode file transfers.

=pod OSNAMES

Linux

=pod SCRIPT CATEGORIES

Networking, UNIX/System_administration