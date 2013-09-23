# Tokaido.app

## Setup

When first cloning this repo, be sure to run the following:

    1. gem install cocoapods
    2. pod install
    3. bundle install
    4. bundle exec rake
    5. open Tokaido.xcworkspace

You should then be able to build and run Tokaido in Xcode.

### how it works

there is a bunch of stuff under the hood that did not bother to understand.  i stripped out stuff that was not relevant to getting a shell up with ruby + calabash + dependent gems installed.

the setup steps above install ruby and gems into a local directory that is used later to build a sandbox.

at application launch, a sandbox directory is created using NSTemporaryDirectory.  the pre-installed ruby (2.0) and the calabash ios and android gems are expanded to that directory.  when the user touches the Start Terminal button in the UI, a shell is opened and the `PATH` variable is massaged so that the sandbox directory because the `GEM_HOME` and the pre-installed ruby becomes the default ruby.

### changing the ruby version

i don't know how to do this.

### changing the calabash version

1. edit the `Tokaido/Gemfile` 
2. `$ rm -rf ./tmp`
3. follow steps 3 and 4 in Setup
4. build and run the Calabash scheme in Xcode

**IMPORTANT** it is probably a great idea to repeat steps 2 - 3 above when you change branches

### changing the About view

i punted on this.  you can edit the `Tokaido/en.lproj/Credits.rtf`  to change the content.

if you want something different, provide a layout/design.

### test

1. archived a build
2. signed and save the Calabash.app to /Applications/
3. logged in as a user that has no special ruby environment (happened to be my jenkins user)
4. launched the app (1st launch failed, but the second did not - could not reproduce)
5. opened a shell using the Calabash.app

* found that the ruby version was 2.0 
* i could execute `calabash-ios console`
* i could run the cucumber tests on the calabash-ios-example    


### bundler and global ~/.bundle/config

i use bundler to pin various projects to specific calabash-cucumber/calabash-android revisions.

```
# be is aliased to 'bundle exec'
$ be cucumber --tags @checkin
Local override for calabash-ios at /Users/moody/git/calabash-ios is using branch 0.9.x but Gemfile specifies 0.9.x-riseup-branch
```

the solution?  do not run with `bundle exec`

### the app

i included a signed app in the repo `./Calabash.app`




