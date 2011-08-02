# Junk

## About

Junk is a simple wrapper around git that tracks all the files you're not supposed to commit. This might include your .rvmrc files, sqlite development databases, and any other local project settings files. It's good for keeping your local configs synced across your development machines.

Behind the scenes, junk moves your tracked files into a git repository stored in ~/.junkd and symlinks to them from their original location. If it finds a .gitignore file, junk will make sure git ignores the symlink. Many junk commands just run the analogous git command in ~/.junkd.

## Install

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

    $ junk add .rvmrc
    $ junk commit -m "tracking my .rvmrc file in junk"

    $ junk remote add origin YOUR_GIT_REMOTE
    $ junk push -u origin master

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
    ~/.junkd

    # to do any custom git stuff like changing your junk remote, just cd to the junk home and go from there.
    $ cd `junk --home`
    # run your git commands here!

    $ cd myproject
    $ junk --drawer
    ~/.junkd/myproject

## Hub support!

Junk supports [hub](https://github.com/defunkt/hub) out of the box. If you have hub installed in your path, junk will see it. This means you can do this:

    $ junk remote add -p origin YOUR_GITHUB_USERNAME/myjunk
    $ junk remote -v
    origin  git@github.com:YOUR_GITHUB_USERNAME/myjunk.git (fetch) # look, hub added expanded your private remote url!
    origin  git@github.com:YOUR_GITHUB_USERNAME/myjunk.git (push)

## License

Junk is licensed under the MIT License. See LICENSE.md for more information.

## Who are you?

I'm [Dave](http://dave.is/).

## That's it?

Well for now! I'm just getting started. Cut me some slack.
