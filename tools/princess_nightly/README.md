# PRINCESS nightly builds

## Information

The nightly build scripts are located in /usr/local/bin on
nomnomnom.seas.harvard.edu. They are run every night at 5:00am and 5:15am (dev
and master branches) by the barrelfish user.

## Set up a new nightly build host

- make a user to own the build (e.g. "barrelfish")
- create a directory called nightly/ in the home directory of that user
- give user rwx ownership over directory
- the script will look for (or create) a nightly/ dir in user's home directory
- clone Guppy repository into ~/nightly/src
- add to new user's crontab with `crontab -e` (this will run the build against
the dev branch every morning at 5am and against the master branch every morning
at 5:30):
    
## Update nightly build scripts

If you have changed the nightly build script, log into the `barrelfish` user in
nomnomnom and replace the scripts stored in `/usr/local/bin`.
