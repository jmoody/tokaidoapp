# Tokaido.app

## Setup

When first cloning this repo, be sure to run the following:

    gem install cocoapods
    pod install
    bundle install
    bundle exec rake
    open Tokaido.xcworkspace

You should then be able to build and run Tokaido in Xcode.


### moody changes

1. fixed a couple of Xcode 5 related compiler errors
2. updated Podfile versions because they caused `pod install` errors
3. edited `Tokaido/Gemfile` to include only calabash-cucumber and calabash-android gems
4. made a couple of changes to the Xcode project to make it build a `Calabash` app (rather than a Tokaido app)

#### test

1. archived a build
2. signed and save the Calabash.app to /Applications/
3. logged in as a user that has no special ruby environment (happened to be my jenkins user)
4. launched the app (1st launch failed, but the second did not - could not reproduce)
5. opened a shell using the Calabash.app

* found that the ruby version was 2.0 
* i could execute `calabash-ios console`
* i could run the cucumber tests on the calabash-ios-example    

#### things that can go wrong

if the shell that pops up cannot find `cucumber` for example. 

* delete your `~/.calabash` directory (was `~/.tokaido`)
* launch a new shell and try again

check the PATH variable

`echo $PATH`

#### rbenv/rvm and the PATH

if you have rbenv or rvm install, i rewrite the PATH variable for the shell and exclude the .rbenv and .rvm directories.

#### bundler and global ~/.bundle/config

i use bundler to pin various projects to specific calabash-cucumber/calabash-android revisions.

```
# be is aliased to 'bundle exec'
$ be cucumber --tags @checkin
Local override for calabash-ios at /Users/moody/git/calabash-ios is using branch 0.9.x but Gemfile specifies 0.9.x-riseup-branch
```

the solution?  do not run with `bundle exec`

#### Converting the Calabash.app into something branded and useful

i just poked around the edges of the Xcode project doing the simple and obvious things.  i don't know where you want to go with this project.

#### the app

i included a signed app in the repo `./Calabash.app`




