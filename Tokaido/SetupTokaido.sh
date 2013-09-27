#!/bin/bash

#  SetupTokaido.sh
#  Tokaido
#
#  Created by Patrick B. Gibson on 10/23/12.
#  Copyright (c) 2012 Tilde. All rights reserved.

clear

# tokaido sandbox path => /var/blah/blah/Calabash-<UUID>
# tokaido path => path to the ruby eg. /var/blah/blah/Calabash-XXXX/Ruby
# tokaido app dir => where to open the shell - always NSUserHomeDirectory

BIN=$CALABASH_SANDBOX_PATH/bin

export TOKAIDO_GEM_HOME=$CALABASH_SANDBOX_PATH/Gems
export GEM_HOME=$TOKAIDO_GEM_HOME
export GEM_PATH=$TOKAIDO_GEM_HOME
export PATH=$BIN:$CALABASH_RUBY_PATH:$GEM_HOME/bin:$PATH


for dir in `echo $PATH | sed "s/:/ /g"`
do
  rbenv=`echo "${dir}" | grep .rbenv`
  if [ -n "${rbenv}" ]; then
      #echo "INFO: found '.rbenv' in path: ${dir} - skipping"
      continue
  fi

  rvm=`echo "${dir}" | grep .rvm`
  if [ -n "${rvm}" ]; then
      #echo "INFO: found '.rvm' in path: ${dir} - skipping"
      continue
  fi

  #echo "INFO: adding ${dir} to path"                                                                                                                                                  
  COMPOSED_PATH="${COMPOSED_PATH}:${dir}"

done

export PATH="${COMPOSED_PATH}"

cd "$CALABASH_LAUNCH_DIR"

echo -e "\033[0;32mThis terminal is now ready use with Calabash.\033[00m"
echo
