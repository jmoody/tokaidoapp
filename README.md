# Calabash.app

download the latest from here: 

https://s3.amazonaws.com/littlejoysoftware/public/Calabash.app.zip

## Setup

When first cloning this repo, be sure to run the following:

    1. gem install cocoapods
    2. pod install
    3. bundle install
    4. rake
    5. open Tokaido.xcworkspace

You should then be able to build and run Calabash in Xcode.

## how it works

there is a bunch of stuff under the hood that did not bother to understand.  i stripped out stuff that was not relevant to getting a shell up with ruby + calabash + dependent gems installed.

the setup steps above install ruby and gems into a local directory that is used later to build a sandbox.

at application launch, a sandbox directory is created using `NSTemporaryDirectory`.  the pre-installed ruby (2.0) and the calabash ios and android gems are expanded to that directory.  when the user touches the Start Terminal button in the UI, a shell is opened and the `PATH` variable is massaged so that the sandbox directory becomes the `GEM_HOME` and the pre-installed ruby becomes the default ruby.

## changing the ruby version

i don't know how to do this.

## changing the gem versions

1. edit the `Tokaido/Gemfile` 
2. `rake clean`
3. follow steps 3 and 4 in Setup (above)
4. **CHANGE THE GEM VERSION INFO IN THE MainWindow.xib**
5. build and run the Calabash scheme in Xcode


**IMPORTANT**  repeat steps 2 - 3 above when you change branches. 

## changing the About view

i punted on this.  you can edit the `Tokaido/en.lproj/Credits.rtf`  to change the content.

if you want something different, provide a layout/design.

## changing the Terminal welcome message

see `Tokaido/SetupTokaido.sh`

## test

1. archived a build
2. signed and save the Calabash.app to /Applications/
3. logged in as a user that has no special ruby environment (happened to be my jenkins user)
4. launched the app 
5. opened a shell using the Calabash.app

* found that the ruby version was 2.0 
* i could execute `calabash-ios console`
* i could run the cucumber tests on the calabash-ios-example    
* successfully launched using `start_test_server_in_background` on
  - iPhone 4S iOS 6
  - iOS 7 Simulator

## bundler and global ~/.bundle/config

i use bundler to pin various projects to specific calabash-cucumber/calabash-android revisions.

```
# be is aliased to 'bundle exec'
$ be cucumber --tags @checkin
Local override for calabash-ios at /Users/moody/git/calabash-ios is using branch 0.9.x but Gemfile specifies 0.9.x-riseup-branch
```

the solution?  do not run with `bundle exec`

in fact, if you use bundle to override gem installations, you should not use `bundle exec`, `bundle update`, or `bundle install` or super ruby madness will ensue.






