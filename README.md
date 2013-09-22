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

found that the ruby version was 2.0 and that i could execute `calabash-ios console`

#### rbenv and the PATH

if you have rbenv installed, the shims are a bit of problem.  when using rbenv PATH variable contains references to the various gem binaries, so a:

`$ which calabash-ios ==> /Users/moody/.rbenv/shims/calabash-ios`

in the shell opened by the Calabash.app will point to the wrong binary.

the solution is to copy the calabash binaries into the `~/.tokaido/bin` directory.

this is probably easy to accomplish, but i didn't bother because i wanted to make sure i was on the right track.

#### Converting the Calabash.app into something branded and useful

i just poked around the edges of the Xcode project doing the simple and obvious things.  i don't know where you want to go with this project.

#### the app

i included a signed app in the repo `./Calabash.app`




