# Junk

## About

Junk tracks all the files you're not supposed to commit to version control. At its core, its just a wrapper around git. Junk creates junk drawers for each of your projects in ~/.junkd, which is a git repository. When you tell junk to track a file, it moves the file into your project's junk drawer and symlinks it from its original location. If you're using git to manage your project, junk will also add the symlink to your .gitignore file. You can then use junk to run common git commands from within your project's drawer.

Junk is useful for tracking your .rvmrc files, sqlite development databases, and any other local project settings files. It's good for keeping your local configs synced across your development machines without polluting your repository.

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
