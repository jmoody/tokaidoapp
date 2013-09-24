root=$PWD
tmp=$root/tmp

if [ -d $tmp/2.0.0-p195 ]
then
  echo "Tokaido Ruby is unzipped"
else
  echo "Unzipping Tokaido Ruby"
  unzip "Tokaido/2.0.0-p195.zip" -d tmp
fi

export PATH=$tmp/2.0.0-p195/bin:$PATH

gem_home="$tmp/bootstrap-gems"

export GEM_HOME=$gem_home
export GEM_PATH=$gem_home

if [ -d $gem_home ]
then
  echo "Bootstrap gems already installed"
else
  mkdir -p $gem_home

  echo "Installing Bundler"
  gem install bundler -E --no-ri --no-rdoc
fi

export PATH=$tmp/bootstrap-gems/bin:$PATH

zips="$tmp/zips"

mkdir -p $zips
cp Tokaido/Gemfile tmp/zips/Gemfile

cd $zips

echo "Removing existing GEM_HOME to rebuild it"
rm -rf gem_home

echo "Building new GEM_HOME"
bundle --path gem_home --gemfile Gemfile --standalone

gem install ~/git/calabash-ios/calabash-cucumber/pkg/calabash-cucumber-0.9.158.gem --install-dir $zips/gem_home/ruby/2.0.0
gem install ~/git/briar/pkg/briar-0.0.9.gem --install-dir $zips/gem_home/ruby/2.0.0


gem install bundler -E --no-ri --no-rdoc -i $zips/gem_home/ruby/2.0.0

rm -f tokaido-gems.zip
rm -rf Gems
cp -R gem_home/ruby/2.0.0 Gems


zip -r tokaido-gems.zip Gems
