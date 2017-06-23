## PRINCESS nightly builds

To set up a nightly build:

- make a user to own the build (e.g. "barrelfish")
- create a directory called nightly/ in the home directory of that user
- give user rwx ownership over directory
- the script will look for (or create) a nightly/ dir in user's home directory
- clone Guppy repository into ~/nightly/src
- add to new user's crontab with `crontab -e` (this will run the build against
the dev branch every morning at 5am and against the master branch every morning
at 5:30):
    
```
0 5 * * * /home/barrelfish/nightly/src/tools/princess_nightly/nightly.sh dev
30 5 * * * /home/barrelfish/nightly/src/tools/princess_nightly/nightly.sh master
```

The way the nightly build works:

nightly.sh pulls Guppy from remote Git repository, rebuilds for x86_64 and
ARMv7, and shoots out an e-mail with the resuls. Only if a build fails with its
STDIN/STDOUT be included in the sent message.
