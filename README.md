# Junk Drawer

## About

Your junk drawer is where you can commit things that you're not supposed to commit to your actual repository. This includes your .rvmrc files, sqlite development databases, and any other local project settings files. It's good for keeping your local configs synced across your own development machines. Your junk drawer is backed by git.

Behind the scenes, junk moves your junk files into a git repository stored in ~/.junk and symlinks to them from the original location.

## Install (doesn't work yet)

    $ gem install junk

## Requirements

Junk requires a version of git. It will probably work with most versions, but I developed it with 1.7.6.

## How it works

    $ cd myproject
    $ junk init
    Alright, myproject now has a junk drawer.

    $ junk add .rvmrc
    Added .rvmrc to your junk drawer.

    # Edit .rvmrc

    # Maybe come up with a `junk status` command? Could that just be `git status` command on a sub directory?

    $ junk save .rvmrc
    $ junk push

    # on your other development machine
    $ cd myproject
    $ junk update
    $ junk link
    Linking in myproject's junk drawer.

## Other commands

    $ junk --prefix
    ~/.junk

    # to do any custom git stuff like changing your junk remote, just cd to the prefix and go from there:
    $ cd `junk --prefix`

## Who are you?

I'm [Dave](http://dave.is/).

## That's it?

Well for now! I'm just getting started. Cut me some slack.
