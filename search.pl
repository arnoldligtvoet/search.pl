#!/usr/bin/perl

require "flush.pl";

# clear screen
# system ("clear");
# system ("cls");

$iamroot    = ($> == 0);        # is the script run by root?
$do_query   = 1;
$do_backups = 1;
$bak        = 'bak';            # suffix for backups (without dot)
$verbose    = 0;
$show_rules = 1;
$paragraph_mode = 0;
$old_format = 0;
$delete_empty_lines = 0;        # delete lines which get replaced to nothing? 
# get the temp_dir from the ENV
$tmp_dir = "$ENV{TMP}";
$sep = "\\"; 			# for dos/windows
# $sep = "/";			# for linux/unix

#---------------------------------------------------------------------------------------------------
# Usage message:
if ($#ARGV == -1) {
print "\n\n================================================================================\n";
print "                         Search and replace by Arnold Ligtvoet\n";
print "                                 Version 0.01d\n\n";
&show_options("default");

print "\n No commandline options set, continuing in interactive mode\n";
print " Directory? : "; $StartDirectory = <>; chomp $StartDirectory;

} else {
print "\n\n================================================================================\n";
print "                         Search and replace by Arnold\n";
print "                                 Version 0.01d\n\n";
print "\n";
&process_options();
}

#---------------------------------------------------------------------------------------------------
# Show help
if ($show_parameters) {
&show_parameters("default");
die " \n";
}
		
#---------------------------------------------------------------------------------------------------
# if defined -curdir
if ( $cur_dir == 1) {

# get the current working directory
$StartDirectory = Win32::GetCwd;
print " Current dir has become searchdir.\n";
}

#---------------------------------------------------------------------------------------------------
#
if (defined $subslist) {
   print "\n Reading file with substitution rules \"$subslist\"\n\n" if $show_rules;

   open(F, "< $subslist") || die " >>> ERROR: can not open substitution list!\n";
   while(<F>) {
     next if /^;/;                              ### ignore this line if it is a comment
     next if /^#/;                              ### ignore this line if it is a comment
     next if /^\s*$/;                           ### ignore this line if it is empty
     s/\n$//;                                   ### chop off CR if there's any
     $substitutions[++$#substitutions] = $_;
     print "   $_\n" if $show_rules;
   }
   close(F);
}
else {
  $substitutions[++$#substitutions] = $search_replace;
}

#---------------------------------------------------------------------------------------------------
#
if (defined $filelist) {
   open(F, "< $filelist") || die " >>> ERROR: can not open file list!\n";
   while(<F>) {
     s/\n$//;                                   
     $files[++$#files] = $_;
   }
   close(F);
}
#---------------------------------------------------------------------------------------------------
# do recursive dir loop to populate @files
if (defined $StartDirectory) {
$Filecase = 0 ;
$found_files = 0;
$arg = shift;
print " File pattern? : "; $FilePattern = <>; chomp $FilePattern;
print " Recurse subdirectories? [n] : "; $RecurseSubdirectories = <>; chomp $RecurseSubdirectories;
if (defined $subslist) {
	print " Substitution file already loaded.\n";
} 
elsif (defined $search_replace) {
	print " Substitution already set on command line.\n";
} 
else {
print " Look for which string? : "; $oldstr = <>; chomp $oldstr;
print " Replace with what? : "; $newstr = <>; chomp $newstr;
$search_replace = "s/$oldstr/$newstr/g";
$substitutions[++$#substitutions] = $search_replace;
}

if ($do_backups == 0) {
	print " Command line option said no backups.";
} else {
		print " Should I make a backup? [n] : "; $do_backups = <>; chomp $do_backups;
		if( $do_backups =~ m#y#i ){
 		 	$do_backups = 1;
 		} else {
  			$do_backups = 0;
		}
}

if( $RecurseSubdirectories =~ m#y#i ){
  $RecurseSubdirectories = 1;
  }else{
  $RecurseSubdirectories = 0;
  }

if( $StartDirectory eq '' ){
  $StartDirectory = '.';
  }

$FilePattern =~ s#\.#\\.#g;
$FilePattern =~ s#\*#.*#g;
$FilePattern =~ s#\?#.#g;
$FilePattern = '(?i)' . $FilePattern unless $FileCase ;

# Create the list of the files

opendir(D,$StartDirectory);
@files = readdir(D);
closedir(D);
@dirs  = grep( (-d "$StartDirectory$sep$_") && /^[^.]/ ,@files);
@files = grep( /^$FilePattern$/ , @files);


for( @files ){ $_ = "$StartDirectory$sep$_" }


while( $RecurseSubdirectories && $#dirs > -1 ){
  
  $cdir = pop @dirs;

  opendir(D,"$StartDirectory$sep$cdir");
  @f = readdir(D);
  closedir(D);

  @d  = grep( (-d "$StartDirectory$sep$cdir$sep$_") && /^[^.]/,@f);
  @f  = grep( $FileCase ? /^$FilePattern$/ : /^$FilePattern$/i , @f);
  for( @d ){
   push @dirs, "$cdir$sep$_";
   }
  for( @f ){
     print " Creating file list, one moment . . .($found_files)\r";
     $found_files++;
     push @files, "$StartDirectory$sep$cdir$sep$_";
   }  
  }
}
#---------------------------------------------------------------------------------------------------
# Don't process any named pipes, sockets or directories
#
print "\n";
$files_checked = 0;
{
  local($i)=0;
  local(@new) = @files;
  

  
  local($old,$reason);
   foreach $file (@files) {
	print " Stripping directory's and other junk ($files_checked)\r"; 
	$files_checked++;

     if    (! -e $file) {
        $reason =  "file does not exist!";
     }
     elsif (-d $file) {
        $reason =  "this is a directory!";
     }
     elsif (-l $file) {
        $reason =  "this is a symbolic link!";
     }
     elsif (-p $file) {
        $reason =  "this is a named pipe!";
     }
     elsif (-S $file) {
        $reason =  "this is a socket!";
     }
     elsif (-z $file) {
        $reason =  "file has zero size!";
     }
     elsif (! -w $file) {
        $reason =  "file is write protected!";
     }
     elsif (! -f $file) {
        $reason =  "this is not a plain file!";
     }
     if ((-d $file)) {
         $old =splice(@new,$i,1);
		 next;
    } 
    
     if ((! -f $file) || (! -w $file) || (-z $file)) {
        $old = splice(@new,$i,1);
        printf(" >>> WARNING: %-26s - omitting \"$old\"\n", $reason);
        next;
     } 
     else {
        $i++;
     }
  }
  @files = @new;
}
print "\n";

   
$mod_no = 0;
#---------------------------------------------------------------------------------------------------
# actual replacing of strings
system("echo trash > $tmp_dir/trash.tmp");
$tempfile = "$tmp_dir/tmp_file.tmp";   
$newstr = '"'.$newstr.'"';
$file_nr = 0;
foreach $file (@files) {
  local($temp_touched) = 0;
  local(@stats,$org_mode,$org_uid,$org_gid); ## we need this to keep track of the original file permissions
  
  $file_nr++;
  
  open(FILE,  "< $file")        || die " >>> ERROR: can not open file $file for reading!\n";
   
  open(NEW,   "> $tempfile")    || die " >>> ERROR: can not open temporary file $tempfile for writing!\n";

  $quit        = 0;             ## stop processing this file?        (after user typed 'q')
  $replace_all = 0;             ## start to replace all occurences?  (after user typed '!')
  @stats = stat(FILE);          ## we need this to keep track of the original file permissions
  $org_mode = $stats[2];
  $org_uid  = $stats[4];
  $org_gid  = $stats[5];
  @commands = ();               ## commands for copying files (for the -mcf option)
  
  print " processing file number $file_nr\r";
  if ($paragraph_mode) { # multi-line matching and paragraph input mode if requested
   $/ = "\n\n"; 
   $* = 1;
}
  
  $line_nr = 1;
  while(<FILE>) {
    local($subs) = 0;

    s/\n$//;            ### instead of chop
    $line = $_;

    if(defined $copy_line) {          ## if we defined a regexp with '-d' to copy a line
       print NEW "$line\n";             ## first print the "original" or non-matching line
       $line_nr++;
       
       if (! eval $copy_line) {       ## if we can rename this line (eg. in UTT-files)
          next;                         ## process the next line...
       }
    } elsif(defined $do_match) {      ## if we defined a regexp with '-m'
       if ($line !~ $do_match) {        ## ignore all lines which do not match the given reg-exp!!
          print NEW "$line\n";          ## and directly write them to the output file
          $line_nr++;
          next;                         ## process the next line...
       }
    } elsif(defined $do_not_match) {  ## if we defined a regexp with '-nm'
       if ($line =~ $do_not_match) {    ## ignore all lines which do match the given reg-exp!
          print NEW "$line\n";          ## and directly write them to the output file
          $line_nr++;
          next;                         ## process the next line...
       }
    }
    

    foreach $search_replace (@substitutions) {
      $subs += eval $search_replace;    # apply this substitution rule
    	warn " >>> ERROR:  $@     DURING EVALUATION OF \'$search_replace\'\n\n" if $@;
    }
    
    if ($subs) {
      
      $mod_no++; 
	if ($do_query) {
          print "\n\n================================================================================" if $verbose;
	    print "file $file_nr: \"$file\"\n";
  	    print "================================================================================\n\n" if $verbose;


	    printf("line %4d : \"%s\"\n", $line_nr, $line);
          print  "        ==> \"$_\"\n";
          print"\n  ($subs substitutions) ";

          if ($replace_all || &ask_user('  substitute? ',*replace_all,*quit)) {
             $line = $_;
             $temp_touched = 1;
             print "  substituted!\n\n";
          }
          else {
             print "  not modified!\n\n";
          }
       }
       else {
          printf("substituted line %4d : \"%s\"\n", $line_nr, $line) if ($verbose);
          printf("(%3d substitutions) to: \"$_\"\n\n", $subs)       if ($verbose);
          $line = $_;
          $temp_touched = 1;
       }
    }
    last if $quit;              ## stop processing this file if user typed 'Q'uit
    
    ## omit to print an empty line, if it was replaced to an empty line
    ## but we want to keep empty lines in the original file, if they are un-touched.

    if ($delete_empty_lines) {
        print NEW "$line\n" if ((!$subs) || ($line ne ""));
    } else {
        print NEW "$line\n";
    }    
    $line_nr++;
  }
  close(FILE);
  close(NEW);

  if ($temp_touched && !$quit) {                        ### if we changed anything and user didn't interrupt
    print " file \"$file\" was modified!\n\n";
    system("copy $file $file.$bak > $tmp_dir\\trash.tmp") if ($do_backups);  ###   make a backup of the original file if requested
    system("mv $tempfile $file > $tmp_dir\\trash.tmp");                       ###   and replace the original file by the modified one
    chmod($org_mode, $file);                            ###   keep permissions as of the original file
    chown($org_uid,$org_gid, $file) if $iamroot;        ###        and keep owner and group id if running as root
    #system("rm $tempfile");
	if ($do_backups) {                                  ###   if we do backups:
       chmod($org_mode, "$file.$bak");                     ###   keep permissions as of the original file
       chown($org_uid,$org_gid, "$file.$bak") if $iamroot; ###        and keep owner and group id if running as root
    }
  }
  else {
    #print "file \"$file\" not modified!\n\n";
    # delete temp_file
    system("rm $tempfile");
  }


  
}

if ( $do_query == 1) {
print " \n processed $file_nr files and found $mod_no hits\n";
} else {
print " \n processed $file_nr files and made $mod_no modifications\n";
}

system("rm $tmp_dir/trash.tmp");

####################################################################################################
#
#   S U B R O U T I N E S : 
#
####################################################################################################

#===================================================================================================
# SUBROUTINE  find unique filename for backup
#
sub find_filename {
    local ($name) = @_;
    while (-e $name) {
      ($a,$b) = split(/;/,$name);
      $b = 'auto' if ($b eq '');
    }
}

#===================================================================================================
# SUBROUTINE  yes_or_no prompting routine :  (CR is NO)
#
sub y_or_n {
    local ($prompt) = @_;
    $/ = "\n" if $paragraph_mode;
    print STDOUT "$prompt (y/n) ";
    local ($answer) = scalar(<STDIN>);
    chomp $answer;
    
    $/ = "\n\n" if $paragraph_mode;
    return ($answer =~ /^y/i) ;                                  ## returns BOOLEAN
}

#===================================================================================================
# SUBROUTINE  enhanced yes or no prompting routine :   yY is YES , nN or CR is NO , ! is ALL further occurances
#
sub ask_user{
    local ($prompt,*all,*quit) = @_;
    $/ = "\n" if $paragraph_mode;
    print STDOUT "$prompt (y/n/!/q) ";
    local ($answer) = scalar(<STDIN>);
    chomp $answer;
    $answer =~ tr/A-Z/a-z/;             ## lowercase the answer

    if ($answer =~ '!') {              ## e.g. replace all further occurances in this file
       $all = 1;
       $quit= 0;
       $answer = 'y';
    } elsif ($answer =~ 'q') {         ## e.g. stop processing this file and keep it untouched
       $all = 0;
       $quit= 1;
       $answer = 'n';
    }

    $/ = "\n\n" if $paragraph_mode;

  #  print "answer = '$answer'\n";

    return ( $answer =~ /y/i ) ;                                  ## returns BOOLEAN
}

#===================================================================================================
# SUBROUTINE  INTERRUPT HANDLER (in case the user hits CTRL-C)
#
sub interrupt_handler {
 print "\n >>> Are you sure you want to quit [Y/n] : "; $quit = <>; chomp $quit;
   
if( $quit =~ m#n#i ){
  $quit = 0;
  
  }else{
  	$SIG{"INT14"} = 'interrupt_handler';
	$quit = 1;
  }


}

#===================================================================================================
# SUBROUTINE  show parameters : (the output should be 80 characters wide)
#
sub show_options
{
   local($note) = @_;
print"\n";
print "	Usage: search {options}\n";
print "\n";
print "	Options : -D		specify directory to search,\n";
print "				no other options required.\n";
print "		  -curdir	start searching from current directory.\n";  
print "		  -help		get more help.\n";
print "\n";
print "	version 0.01d\n";
print "	Arnold Ligtvoet.\n";

}
#===================================================================================================
# SUBROUTINE  show parameters : (the output should be 80 characters wide)
#
sub show_parameters
{
   local($note) = @_;

                                          
print "USAGE:	search -D {directory}\n";
print "	search {options}\n";
print "\n";
print "OPTIONS:\n";
print "-s  {str}	substitution in PERL format (eg.: s/aha/haha/g)\n";
print "-S  {str}	alternatively you can provide a file\n";
print "		containing PERL search/replace expressions.\n";
print "		This way you can do multiple search/replaces\n";
print "-f  {str}	one or more space separarted filenames\n";  			          
print "		this has to be the last option!\n";
print "-F  {str}	alternatively you can provide a file\n";
print "		containing the list of files to be processed\n";
print "-D  {str}	specifiy the start directory for recursive search\n";	 
print "		and answer questions (easy !)\n";
print "-curdir		start searching from current directory.\n";
print "-b  {str}	suffix for backup files\n";                          
print "-nb		don't create backup files\n";              			         
print "-nq		don't query, replace without asking\n";			             
print "\nAlso see readme.txt for more information on features";
}
#===================================================================================================
# SUBROUTINE  Process the Options:
#
sub process_options {

    $args = @ARGV;
    $arg_error = 0;     # FALSE

    while (@ARGV) {
      
      if ($ARGV[0] eq '-o') {
        shift(@ARGV);
        $oldstr = $ARGV[0];
        $old_format = 1;
        shift(@ARGV);
      }
      elsif ($ARGV[0] eq '-n') {
        shift(@ARGV);
        $newstr = $ARGV[0];
        $old_format = 1;
        shift(@ARGV);
      }
      elsif ($ARGV[0] eq '-s') {
        shift(@ARGV);
        $search_replace = $ARGV[0];
        shift(@ARGV);
      }
      elsif ($ARGV[0] eq '-nb') {
        shift(@ARGV);
        $do_backups = 0;
      }
      elsif ($ARGV[0] eq '-curdir') {
        shift(@ARGV);
        $cur_dir = 1;
      }
# not used 
#      elsif ($ARGV[0] eq '-del') {
#        shift(@ARGV);
#        $delete_empty_lines = 1;         # do delete lines which are empty after all substitutions
#      }
#      elsif ($ARGV[0] eq '-mcf') {
#        shift(@ARGV);
#        $modify_filenames = 1;           # consider the given regexp's as filenames...
#      }
#      elsif ($ARGV[0] eq '-m') {
#        shift(@ARGV);
#        $do_match = $ARGV[0];            # read the regular expression
#        shift(@ARGV);
#      }
#      elsif ($ARGV[0] eq '-nm') {
#        shift(@ARGV);
#        $do_not_match = $ARGV[0];        # read the regular expression
#        shift(@ARGV);
#      }
#      elsif ($ARGV[0] eq '-d') {
#        shift(@ARGV);
#        $copy_line = $ARGV[0];           # read the search/replace regular expression
#        shift(@ARGV);
#      }
      elsif ($ARGV[0] eq '-b') {
        shift(@ARGV);
        $bak = $ARGV[0];
        $bak =~ s/^\.//;                 # remove initial point, if any
        shift(@ARGV);
      }
      elsif ($ARGV[0] eq '-p') {
        shift(@ARGV);
        $paragraph_mode = 1;
      }
      elsif ($ARGV[0] eq '-v') {
        shift(@ARGV);
        $verbose = 1;
      }
      elsif ($ARGV[0] eq '-nq') {
        shift(@ARGV);
        $do_query = 0;
      }
      elsif ($ARGV[0] eq '-F') {
        shift(@ARGV);
        $filelist = $ARGV[0];           # read the name of the file with the filelist
        shift(@ARGV);
      }
      elsif ($ARGV[0] eq '-D') {
        shift(@ARGV);
        $StartDirectory = $ARGV[0];           # read the name of the directory for recusrsive search
        shift(@ARGV);
      }
	elsif ($ARGV[0] eq '-help') {
        shift(@ARGV);
        $show_parameters = 1;           # display the help text
        shift(@ARGV);
      }
      elsif ($ARGV[0] eq '-S') {
        shift(@ARGV);
        $subslist = $ARGV[0];           # read the name of the file with the substitutions
        shift(@ARGV);
      }
      elsif ($ARGV[0] eq '-f') {
        shift(@ARGV);
        @files = @ARGV;
        $#ARGV = -1;
      }
      else {
        $arg_error = 1;    # TRUE
        warn "
     ... unknown option $ARGV[0] ...
    \n";
        shift(@ARGV);      # remove the bogus option
      }
     };

    if ($arg_error) {
      &show_parameters("set to");
        die "
     ... dying due to unknown options (as listed above) ...
    \n"
    }
}

####################################################################################################

