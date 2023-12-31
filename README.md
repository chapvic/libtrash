# libtrash - a shared library which implements an 'intelligent', highly configurable "recycle bin" or "trash can" under GNU/Linux.
## (Forked from [Libtrash](https://github.com/termih/libtrash))

Written by Manuel Arriaga (marriaga@stern.nyu.edu).

Copyright (C) 2001-2014 Manuel Arriaga 
Licensed under the GNU General Public License version 2. See the file COPYING for details.

### Version: 3.3 (2014/Jun/08)

## IMPORTANT NOTE regarding Firefox and Google Chrome:

IMPORTANT NOTE ON FIREFOX AND GOOGLE CHROME: On some systems, due to
some mysterious interaction, Firefox segfaults or fails to start when
libtrash is enabled. Google Chrome may just not start at all without
emitting any error. The simple way around this problem is to disable
libtrash for Firefox and Chrome. Do so by starting Firefox with the
command "LD_PRELOAD= firefox" and Chrome: "LD_PRELOAD=
google-chrome-stable". You can bind this command (if necessary by
placing it in a one-line bash script file by itself) to whatever GUI
icon or hotkey combination you use to start Firefox. You may also
modify your desktop file to include LD_PRELOAD= on the Exec= line. 


## REQUIREMENTS:

- (POSSIBLY) /proc filesystem: to run libtrash in most recent systems, you
need to be running a kernel with support for the /proc file system
(CONFIG_PROC_FS). Do not worry, since compilation will fail with a warning
if this requirement applies to you and you don't have it enabled.

- To *compile* libtrash, you need both Perl as well as Python.


## DESCRIPTION:

libtrash is a shared library which, when preloaded, will intercept calls to
a series of GNU libc functions and make sure that, if an attempt to destroy
certain files is made, these won't be permanently destroyed but rather moved
to a "trash can".  It also allows the user to mark certain directories as
"unremovable", which means that calls to functions which would result in the
loss of files under these directories will always fail, leaving those files
untouched in their original locations.

(This last feature is meant as a higher-level substitute for ext2fs'
"immutable" flag for use by those of us who rely on other file systems. An
important difference is that libtrash allows non-privileged users to use
this with their personal files.)

The GNU libc functions which can be overriden/"wrapped" are:

- unlink() / unlinkat();
- rename() / renameat();
- fopen() / fopen64();
- freopen() / freopen64();
- open() / openat() / open64() / openat64() / creat() / creat64().

### You can individually enable / disable each of these "protections"; by default, only calls to the first two functions are intercepted.

### IMPORTANT NOTE 1:
The wrappers of the "open functions" (fopen, freopen and open) behave differently from the real functions in an important way when they are asked to open - in either write-mode or read-plus-write-mode - a file considered "worthy" of having a copy of itself stored in the trash can before being truncated: while the functions in GNU libc require write-permission to that already existing file for the call to succeed, these wrappers require write-permission to the DIRECTORY WHICH HOLDS THAT FILE instead. This is so because, in fact, we are renaming the existing file before opening it, and calls to rename() require write-permission to the directory which holds the file for them to succeed. Usually, you only have write-permission to files in directories to which you also have write-permission, so this shouldn't be a huge problem in most cases.

### IMPORTANT NOTE 2:
When a file on a partition / filesystem other than the one in which your trash can resides is destroyed, libtrash can't just use the GNU libc function rename() to move it into your trash can: it must copy that file byte-after-byte into your trash can and then delete the original. To achieve that, read-permission to the destroyed file is required. Since in
most situations you don't have write-permission to a directory which holds files you can't read, hopefully that won't prove a big problem, either. However, be warned that copying a file (especially a large one) will take a lot longer than the time which would be required to simply rename it.

### IMPORTANT NOTE 3:
If you are running a web (or other) server as user 'nobody', then you should ensure that libtrash is not active for that process. The issue is that by default libtrash refuses to remove files if it will not be able to save them in that user's trash can. The 'nobody' account typically lacks a (writable) home directory; as such, when processes run as 'nobody' try to remove a file, libtrash will always make that operation fail. For that reason, always start servers run through the 'noboby' account (or any other, 'low privileges' account missing a writable home dir) with libtrash disabled (just prefix "LD_PRELOAD= " to the command line). (My thanks to Nicola Fontana for pointing this out!)

```
libtrash works with any GNU/Linux program, both at the console and under XFree86, and operates independently of the programming language the program was written in. The only exception are statically linked programs, which you
probably won't find. It can be extensively configured by each user through a personal, user-specific configuration file. Although libtrash itself was written in C, the installation procedure requires both Perl and Python (sorry!).
```

## HOW libtrash WORKS / FEATURES: 

libtrash recreates the directory structure of your home directory under the trash can, which means that, should you need to recover the mistakenly deleted file /home/user/programming/test.c, it will be stored in /home/user/Trash/programming/test.c. If you have instructed libtrash to also store copies of files which you delete in directories outside of your home dir (see libtrash.conf for details), they will be available under Trash/SYSTEM_ROOT. E.g.: after deletion by the user joe, /common-dir/doc.txt will be available at /home/joe/Trash/SYSTEM_ROOT/common-dir/doc.txt.

When you try to delete a file in a certain directory where you had previously deleted another file with the same name, libtrash stores the new file with a different name, in order to preserve both files. E.g.:
```bash
$ touch test 
$ rm test 
$ ls Trash/
test 
$ touch test 
$ rm test 
$ ls Trash/ 
test test[1] <-- The file we deleted first wasn't lost. 
```
libtrash keeps generating new names until no name collision occurs. The deletion of a file never causes the permanent loss of a previously "deleted" file.

__Temporary files can be automatically "ignored" and really destroyed.__

You can define whether you wish to allow the definitive removal of files already in your trash can while libtrash is active. Allowing this has one major disadvantage, which is explained in libtrash.conf. But, on the other hand, if you don't allow the destruction of files already in your trash can, when you need to recover HD space by permanently removing files  currently found in your trash can you will have to temporarily disable libtrash first (instructions on how to achieve this can be found below). 

To avoid the accumulation of useless files in your users' trash cans, it is probably wise to run the script cleanTrash regularly (perhaps from a cron job). This Perl script was kindly provided by Daniel Sadilek and works by removing the oldest files from each trash can in your system whenever that trash can grows beyond a certain disk size. It is meant to be run by root. cleanTrash, together with the license according to which it can be distributed and a short README file written by me, can be found under the directory "cleanTrash".

You can also choose whether files outside of your home directory, hidden files (and files under hidden directories), backup and temporary files used by text editors and files on removable media should be handled normally or "ignored" (i.e., you can decide if copies of such files should be created in your trash can if the originals are about to be destroyed). It is also possible to discriminate files based on their names' extensions: you can instruct libtrash, e.g., to always ignore object files (files with the extension ".o"), meaning that deleting files of this type won't result in the creation of copies of these in your trash can. By default, besides object files, TeX log and auxiliary files (".log" and ".aux", respectively) are also ignored.

The user may also configure libtrash to print a warning message to stderr after each "dangerous" function call while libtrash is disabled. This feature is meant to remind the user that libtrash is disabled and that, for that reason, any deletions will be permanent. This feature is disabled by default, so that libtrash remains "invisible" to the user.

Other options: name of trash can, name of TRASH_SYSTEM_ROOT under your trash can, whether to allow the destruction of the configuration file used by libtrash, and what to do in case of error. You can also set in your environment a list of exceptions to the list of unremovable directories.

To configure libtrash so that it better suits your purposes you should edit the file libtrash.conf before compiling. Even if you won't be configuring libtrash at compile-time, it is recommended that you at least read config.txt so that you know how libtrash handles its configuration files.

## CONFIGURING, COMPILING, INSTALLING AND ACTIVATING libtrash:

To configure:

1. Edit the file libtrash.conf. All options are (verbosely) explained there. If you want to learn about the different features libtrash offers, that is where you want to look; otherwise just check that the default settings look ok to you.

To compile:

2. Run "make".

To install:

3. Edit the Makefile, possibly choosing alternative locations for the shared library and the system-wide, uneditable configuration file (defaults: /usr/local/lib and /etc/libtrash.conf, respectively).

4. Run, as root, "make install".

This installs libtrash in the directory specified at the top of the Makefile, runs ldconfig and puts a system-wide configuration file in /etc/libtrash.conf reflecting the compile-time defaults used. NEVER EDIT THIS FILE. USE A PERSONAL CONFIGURATION FILE INSTEAD. 

```
Note that you can also install libtrash on your home directory: just edit the top of the file src/Makefile and run 'make install' from your account.
```

5. Now go and read config.txt.


To activate libtrash:

6. So that calls to the different GNU libc functions are intercepted, you must "preload" this library. What I have found to be the best way to do this is to configure your shell so that:

- the environment variable LD_PRELOAD is set to the path to the libtrash library
- alias the "su" command to "su -l"
               
If you use Bash, this translates into adding the following two lines to one of Bash's initialization files (/etc/profile or ~/.profile):

```bash
export LD_PRELOAD=/usr/local/lib/libtrash.so 
alias su="su -l"
```

Notice that you should replace the path in the first line with the location of libtrash on your system. (If you installed it in the default place you do not need to edit it.)

The second line merely ensures that if you su into a different account the LD_PRELOAD variable will also be set. (This is important to avoid nasty surprises!) At least on my system, and unlike what some of the documentation suggests, passing the option "-" to su is NOT enough to get LD_PRELOAD correctly set in the new shell. The "-l" option, which some say is
equivalent to "-", does the trick for me.

## TESTING libtrash: 

libtrash should now be set up and ready to spare you a lot of headaches. You can test drive it by doing the following (assuming that you didn't change TRASH_CAN to a string other than "Trash"):

1. Create a file called test_file
2. Open test_file with a text editor, type a few characters and save it.
3. Run the following commands:

```bash
$ rm test_file 
$ ls Trash/
```

test_file should now be stored in Trash/. But don't be fooled by this example! libtrash isn't restricted to "saving" files which you explicitly deleted with "rm": it also works with your (graphical) file manager, mail user agent, etc...

### NOTE 1:
Simply "touching" a test file -- ie, "touch test_file" -- and then removing it will no longer put it in the trash can, because libtrash now ignores empty files, since their removal doesn't present a risk of data loss.

### NOTE 2:
To make sure that you are fully covered even when su'ing into other accounts, you can try the following (this assumes you can su into the root account on this machine and that you are using Bash):

```bash
$ su -c "set|grep LD_PRELOAD"
```

If a line like 

```bash
LD_PRELOAD=/usr/local/lib/libtrash.so
```

is shown that means you are all set! (If not, see the previous section on how to make sure that su sets the LD_PRELOAD environment variable.)

## SUSPENDING/RESUMING/CIRCUMVENTING libtrash:

Should you need to temporarily disable libtrash, you can do so by running the command

```bash
$ export TRASH_OFF=YES
```

When you are done, libtrash can be reactivated by typing:

```bash
$ export TRASH_OFF=NO
```

You might make these operations simpler by appending the following two lines to the init file you used in step 5) above (if you are using Bash as your shell):

```bash
alias trash_on="export TRASH_OFF=NO" 
alias trash_off="export TRASH_OFF=YES"
```

After doing so, you can enable/disable libtrash by typing 

```bash
$ trash_on
```

or

```bash
$ trash_off
```

at the prompt.

If you often need to remove one or more files in a definitive way using 'rm', you might wish to define 
alias `hardrm="TRASH_OFF=YES rm"`

After having done so,

```bash
hardrm file.txt
```

will achieve the same effect as 

```bash
TRASH_OFF=YES rm file.txt
```

```
NOTE: I strongly advise AGAINST defining such an alias, because you will probably get into the habit of always using it: at the time you delete a file, you are always sure that you won't need it again... :-) The habit of using that alias effectively makes installing libtrash useless. Unless you wish to effectively do away with the file due to privacy/confidentiality concerns, think instead of how cheap a gigabyte of HD space is! :-)
```

If you have set the option SHOULD_WARN (see libtrash.conf), running a command while TRASH_OFF is set to "YES" will result in libtrash printing to stderr (at least) one reminder that it is currently disabled.


## LIMITATIONS:

1. As mentioned in the second note near the top of this document, destroying documents in a partition different from the one on which your home directory resides will result in a byte-after-byte copy of those files into your trash can. If I could think of a faster, more efficient way of doing that I would have already implemented it. Unfortunately, things like quota-support and access permissions make this problem hard to solve. Unless someone suggests a good way to overcome this, this isn't going to change any time soon... Sorry!

2. As mentioned in the section on how to activate libtrash, the LD_PRELOAD method doesn't protect you from mistakes while using an account in which (for any reason) LD_PRELOAD isn't set and pointing to libtrash. If you 'su' into other accounts, you should (i) make sure that, by default, they have LD_PRELOAD pointing to libtrash and (ii) always use "su - username",
instead of "su username".

#### The only alternative is to activate libtrash from /etc/ld.so.preload.


## CONTACT:

This library was written by me, Manuel Arriaga. Feel free to contact me at marriaga@stern.nyu.edu with questions, suggestions, bug reports or just a short note saying how libtrash helped you or your organization deploy GNU/Linux in a context where some "user friendliness" in handling file deletions is required.

## CREDITS:

- Avery Pennarun, whose "freestyle-concept" tarball showed me how to intercept function calls and write a suitable Makefile.

- Phil Howard and wwp for pointing out problems with the (abandoned) hardrm script. wwp also offered general advice.

- Karl Pitrich for letting me know about a bug in the calls to mkdir() and chmod() in the code of dir_ok() which rendered the trash can (and all subdirs) unbrowsable if you didn't manually correct their permissions with 'chmod'.

- Daniel Sadilek for letting me know that some people _did_ need inter-device support :), the helpful cleanTrash Perl script and help testing libtrash-0.6.

- Ross Skaliotis for helping me pin down the cause of the incompatibility between libtrash and Samba.

- Christoph Dworzak for reporting poor handling of special files, and providing a patch.

- Martin Corley for the alternative cleanTrash script.

- Frederic Connes for reporting a bug affecting the creation of replacement files when open()/open64() are being intercepted and suggesting the use of different names for 5 configuration variables. Frederic also provided two patches against the Makefile and cleanTrash script.

- Dan Stutzbach for reporting a bug in the function readline(), sending a patch and helping me fix it.

- Ryan Brown for reporting a memory leak.

- BBBart for reporting a bug in the handling of files with names starting with multiple dots.

- Jacek Sliwerski (rzyjontko) for adding the IGNORE_RE feature to libtrash and making the search for new filenames `in reformulate_new_path()` much faster.

- Robert Storey for reporting an error in the documentation.

- Raik Lieske for reporting a bug in the handling of certain file paths.

- David Benbennick for reporting mishandling of function calls with a NULL pathname.

- Jorgen Schaefer for helping me figure out why glibc was crashing when libtrash was active and getwc() was called.

- Philipp Woelfel for alerting me to lacking coverage of the *at() functions and allowing me access to his system to find out what was going on. Also, Philipp spotted the "unresolved symbol" bug in 2.7.

- Nicola Fontana for pointing out the problem with servers running as 'nobody'.

- Peter Hyman for pointing out that the default value of REMOVABLE_MEDIA_MOUNT_POINTS was outdated.

- Kamil Dudka for sending me a patch renaming the _init/_fini functions to avoid symbol clashes when using Audacious plugins.

- Peter Hyman (again :) ) for letting me know that Google Chrome (and not just some versions of Firefox) also need to be launched with 'LD_PRELOAD='.

## Homepage

Homepage: [Libtrash homepage](http://pages.stern.nyu.edu/~marriaga/software/libtrash/)
