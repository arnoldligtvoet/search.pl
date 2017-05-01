============================================================================================
README.TXT for SEARCH							  BY Arnold Ligtvoet
									       version 0.01d
============================================================================================

Contents:
1. General description 
2. Installation
3. Usage
4. Usage (advanced)
5. Author 

============================================================================================
1. General description
Search is a utility for searching strings in ASCII text documents. It also provides the 
capability to replace the found strings with another string. Search works in the DOS and Linux 
environnement and requires Perl to be installed.

2. Installation
Very easy. Unzip this archive (duh!) and copy the files into a new directory. Open the searh.pl
script and modify the $sep parameter to match your system. 

3. Usage
Start with paramater -D {directory-name} to get interactive prompting for other parameters.
Search will now ask for a file-pattern (e.g. '*' for all files or '*.htm' for all files
with the extension .htm). 
When the search string is found and option -nq is not set, Search will display the file-
name, the old string and the string with the replacement in place. It will than ask the 
user if the string can be replaced. The following options are available:
y : replace the found string (only this one)
n : do not replace and skip to next found string
! : replace all found strings in all files
q : quit working this file and skip to next file

Parameters -s -S -nb -b -nq also work in this mode ( see below
for a description).

4. Usage (advanced)
Search takes several commandline options:

-D 		: see chapter 3
-curdir		: Same as -D but takes the current working directory as start
		  for the search.
-s {s/old/new/g}: specify a PERL search/replace string on the command line. This option
		  will let you specify the search/replace string like 's/old/new/g' to 
		  replace the word 'old' with the word 'new'. It is also possible to
		  match and replace multi-word strings by entering 
		  's/"old words"/"new words"/g'.
-S {filename}	: specify a file containing PERL search/replace strings. Usefull for doing
		  a multiple search and replace on the specfied directory (with the -D 
		  option), a specified file (-f) or multiple files (-F).
		  See replace.txt for an example.
-f {filenames}	: specify one or more space seperated filenames that need to be searched.
		  This option has to be the last option on the commandline. Alsways use
		  this option together with -S or -s and not in the interactive mode (-D).
-F {filename}	: specify filename for file that contains filenames of files that need
		  to be searched. Create a file containing the filenames of the files
		  that need to be searched (one filename per line). Always use with -S or
		  -s, not in interactive mode (-D).
		  See files.txt for an example.
-b {extension}	: create backupfiles with other extension than 'bak'. This option lets
		  you set another extension for the backupfiles for instance 'tmp', default 		  'bak'. When this option is set Search automaticly, without prompting, 		  makes backups.
-nb		: do no make backups and don't prompt me for them (no parameters). This
		  option can be used in interactive mode and commandline mode.
-nq		: do not query. With this option set Search will not query the user for
		  any replacements, it will just make them.
-help		: display help text.

5. Author
Arnold Ligtvoet 
arnold@ligtvoet.org