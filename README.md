# Junk

## About

Junk is a light wrapper around git. Your junk drawer is where you can commit things that you're not supposed to commit to your actual repository. This includes your .rvmrc files, sqlite development databases, and any other local project settings files. It's good for keeping your local configs synced across your own development machines.

Behind the scenes, junk moves your junk files into a git repository stored in ~/.junk and symlinks to them from the original location. Many junk commands just run the analogous git command in ~/.junk.

## Install (doesn't work yet)

    $ gem install junk

## Requirements

Junk requires a version of git. It will probably work with most versions, but I developed it with 1.7.6.

## How it works

    $ cd myproject
    $ junk init
    Alright, /path/to/myproject now has a junk drawer.

    $ junk track .rvmrc
    Now tracking .rvmrc in your junk drawer

    # Edit .rvmrc

    $ junk status
    # runs git status in your junk drawer

    $ junk add .rvmrc # proxy's to git
    $ junk commit -m "tracking my .rvmrc file in junk"

    $ junk remote add YOUR_GIT_REMOTE
    $ junk push

    # on your other development machine
    $ cd myproject

    # for first time setup
    $ junk clone JUNK_REPO

    # or if you have already cloned the repo
    $ junk pull

    $ junk link
    Linking in myproject's junk drawer.

## Other commands

    $ junk --home
    ~/.junk

    # to do any custom git stuff like changing your junk remote, just cd to the junk home and go from there.
    $ cd `junk --home`
    # run your git commands here!

## Who are you?

I'm [Dave](http://dave.is/).

## That's it?

Well for now! I'm just getting started. Cut me some slack.
