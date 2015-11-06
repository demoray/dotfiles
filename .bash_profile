export PATH=/usr/local/bin:$(brew --prefix ruby)/bin:/Users/$(USER)/checker-275:$PATH:/Users/$(USER)/projects/android/adt-bundle-mac-x86_64-20130729/sdk/platform-tools:/Users/$(USER)/projects/android/adt-bundle-mac-x86_64-20130729/sdk/tools/:$HOME/bin
export EDITOR=vim
export HISTFILESIZE=10000000000000

export PACKER_CACHE_DIR=~/Downloads/packer_iso_cache

if [ -d /usr/local/lib/python2.7/site-packages ]; then
    export PYTHONPATH=/usr/local/lib/python2.7/site-packages:$PYTHONPATH
fi
