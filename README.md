futil
=======


SCRIPT3 note:
-------------
This project is a script sub-library and is part of a larger project managed
as a Google-repo called "SCRIPT3" (or "s3" for short). S3 can be found
here: https://github.com/mambrus/script3

To download and install any of s3's sub-projects, use the Google's "repo" tool
and the manifest file in the main project above. Much better documentation
there too. 

Note that most of s3's sub-project files won't operate without s3 easily (or
at all).


Commands
--------

# futil.pscp.sh


This command is intended to be similar to the UNIX scp but much faster under
favourable circumstances. A "typical" use-case would be on a 10Mb/s network
(throttled) copying the GNU build-chain including build out-put where both
end machines had 8 cores which were basically idle.

* scp: 6m4.525s
* futil.pscp.sh: 2m26.063s (23.2MB/s)

It was noticed that scp had a hard time even filling up the bandwith, and
was often laying on 5Mb/s or less, while pscp was willing the band-with fully.

The speed increase could had been much greater, but is as alway limited by
the weakest link:

time dd if=/dev/zero of=/tmp/test bs=1M count=1k
1024+0 records in
1024+0 records out
1073741824 bytes (1.1 GB) copied, 11.5531 s, 92.9 MB/s

I.e. 93MB/s was the disks fastest write time for continuous files, for lot's
of small files seek-time is added.

All-in-all a speed-increase of 2-3x compared with scp is the least to expect
on a medium-to-fair bandwidth network. On a slow network and under ideal
conditions (pure text) it can in theory be ~10N where N is the amount of
CPU's on the sending side.

## Differences to scp syntax.

The syntax of "from" and "to" scp is very similar to scp, but not quite:
* It matters if destination path ends with a "/" or not. The latter means
  user want to copy into that directory. Directory will be created if it
  doesn't exist already. This matters especially for absolute destination
  paths and/or when the source is not a directory but a file.

