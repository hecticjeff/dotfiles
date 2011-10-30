#!/bin/sh
set -e

DOTFILES=${DOTFILES:-"$HOME/.dotfiles"}

# Run the script from the dotfiles directory
cd "$DOTFILES"

# gitconfig
if [ ! -f "$HOME/.gitconfig" ]; then
  echo "No ~/.gitconfig detected, configuring"
  sh -c "$(curl -fsSL https://github.com/hecticjeff/dotfiles/raw/master/bin/git-create-config)"
fi

# dotfiles
if [ ! -d "$DOTFILES" ]; then
  git clone "https://github.com/hecticjeff/dotfiles" "$DOTFILES"
fi

# janus
if [ ! -f "$HOME/.vim/README.markdown" ]; then
  sh -c "$(curl -fsSL https://github.com/carlhuda/janus/raw/master/bootstrap.sh)"
fi

# global flags for installing dotfiles
skip_all=false
overwrite_all=false
backup_all=false

# loop over all the `.symlink` files
for linkable in **/*.symlink
do
  # reset these to false at the start of each loop
  overwrite=false
  backup=false
  skip=false
  quit=false

  # file that we are symlinking to
  source="$DOTFILES/$linkable"

  # the target for the symlink
  target="$HOME/.`basename $linkable .symlink`"

  # check if the target is an existing file that's not a symlink.
  if [ -f "$target" -a ! -L "$target" ]; then

    # check that we're not already on an *_all flag
    if ( ! $overwrite_all && ! $backup_all ); then

      if [ "$OVERWRITE_OPTION" ]; then
        confirm=$OVERWRITE_OPTION
      else
        # ask the user how they want to proceed
        /bin/echo -n "file exists $target [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all, [q]uit: "
        read confirm
      fi

      # check the user's choice
      case "$confirm" in
        o) overwrite=true ;;
        b) backup=true ;;
        s) skip=true ;;
        O) overwrite_all=true ;;
        B) backup_all=true ;;
        S) skip_all=true ;;
        q) quit=true
      esac
    fi

    # exit with a failure if the user wants to quit.
    if ( $quit ); then
      echo "quitting..."
      exit 1
    fi

    # break out of the loop if we're skipping all
    if ( $skip_all ); then
      echo "skipping all"
      break
    fi

    # continue to the next file if we're skipping this one
    if ( $skip ); then
      echo "skipping $target"
      continue
    fi

    # move the file out of the way if the user wants to backup
    if ( $backup || $backup_all ); then
      echo "backing up $target"
      mv "$target" "$target.backup"
    elif ( $overwrite || $overwrite_all ); then
      echo "overwriting $target"
      rm -rf "$target"
    fi
  fi

  # finally link in the file
  echo "Linking ${target} -> ${source}"
  ln -nfs "$source" "$target"

done

# upgrade janus
# TODO: this is a bit hit and miss at the moment due to gem permissions
/bin/echo -n "Upgrade janus? (y/n): "
read upgrade_janus
if [ "$upgrade_janus" = "y" ]; then
  cd ~/.vim
  rake upgrade
fi
