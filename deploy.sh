#!/usr/bin/env bash

# https://github.com/farvardin/dotfiles
# https://sourceforge.net/p/farvardin-dotfiles/code/ci/default/tree/
#
# this script won't delete your existing configuration

DIFF=meld

apt-mini() {
	printf "We will install some basic deb packages on the system. \n\n"
	sleep 2
	sudo apt install xterm meld scite byobu gimp inkscape focuswriter geany micro exuberant-ctags fzf
}

apt-extra() {
	printf "We will install some more deb packages on the system. \n\n"
	sleep 2
	sudo apt install gimp-gmic gmic blender veracrypt gocryptfs hatari gforth freeplane mcomix nextcloud-desktop retroarch syncthing calibre vlc
}

# Deploy a single file as a symlink (default) or copy to $HOME/$src
deploy_file() {
	local src="$1"
	local mode="${2:-link}"
	local dest="$HOME/$src"
	local dest_dir
	dest_dir="$(dirname "$dest")"

	mkdir -p "$dest_dir"

	if [ -e "$dest" ]; then
		echo -e "$dest is already present on your system."
		if cmp -s "$src" "$dest" 2>/dev/null; then
			printf '   The files are the same \n\n'
		else
			printf '\n   The files are different, do you want to compare them? (y/n):\n'
			read -r answer
			if [[ "$answer" == "y" ]]; then
				$DIFF "$src" "$dest"
			fi
			echo -e "Backup $dest to $dest.old and install dotfile? (y/n)"
			read -r answ2
			if [[ "$answ2" == "y" ]]; then
				mv "$dest" "$dest.old"
				if [[ "$mode" == "copy" ]]; then
					cp "$PWD/$src" "$dest"
				else
					ln -s "$PWD/$src" "$dest"
				fi
				printf "Done.\n"
			else
				printf "Nothing was changed.\n"
			fi
		fi
	else
		if [[ "$mode" == "copy" ]]; then
			cp "$PWD/$src" "$dest"
			echo -e "\033[1mCOPYing\033[0m \033[4m$src\033[0m to $dest ..."
		else
			ln -s "$PWD/$src" "$dest"
			echo -e "\033[1mlinking\033[0m \033[4m$src\033[0m to $dest ..."
		fi
	fi
}

# Deploy a directory as a symlink to $HOME/$src
deploy_folder() {
	local src="$1"
	local dest="$HOME/$src"
	local dest_dir
	dest_dir="$(dirname "$dest")"

	mkdir -p "$dest_dir"

	if [ -e "$dest" ]; then
		echo -e "$dest is already present on your system."
		ls -alh "$dest"
		printf 'If it is not already linked, do you want to compare the folders? (y/n):\n'
		read -r answer
		if [[ "$answer" == "y" ]]; then
			$DIFF "$src" "$dest"
			echo -e "Backup $dest to $dest.old and link? (y/n)"
			read -r answ2
			if [[ "$answ2" == "y" ]]; then
				mv "$dest" "$dest.old"
				ln -s "$PWD/$src" "$dest"
				printf "Done.\n"
			else
				printf "Nothing was changed.\n"
			fi
		fi
	else
		ln -s "$PWD/$src" "$dest"
		echo -e "\033[1mlinking\033[0m \033[4m$src\033[0m to $dest ..."
	fi
}

deploy_dotfiles() {

	# current status
	echo -e "\n\n\033[1mCurrent files status:\033[0m"
	for R in .bashrc .ctwmrc .ctags garglk.ini .gvimrc .hgrc .inputrc .profile .SciTEUser.properties .tmux.conf .vimrc .jedrc .vim .emacs .config/emacs .nanorc .Xresources .Xresources-monochrome .config/gforthrc0; do
		ls -alh ~/"$R" 2>/dev/null
	done
	echo -e "\n\n"

	# home files
	for R in .bashrc .ctwmrc .ctags garglk.ini .gvimrc .hgrc .inputrc .profile .SciTEUser.properties .tmux.conf .vimrc .jedrc .emacs .nanorc .Xresources .Xresources-monochrome; do
		deploy_file "$R"
	done

	# single .config file
	deploy_file .config/gforthrc0

	# .config/redshift.conf — AppArmor prevents symlinks, must copy
	deploy_file .config/redshift.conf copy

	# home folders
	for R in .vim .scite .dgen Gophie; do
		deploy_folder "$R"
	done

	# .config folders
	for R in .config/emacs .config/ghostwriter .config/castor .config/geany .config/nvim .config/micro; do
		deploy_folder "$R"
	done

	# .local/share
	deploy_folder .local/share/GottCode/FocusWriter/Themes
	deploy_folder .local/share/cool-retro-term

	# .atom (reminder: install the file-watcher package)
	for R in .atom/styles.less .atom/config.cson; do
		deploy_file "$R"
	done

	# mednafen
	deploy_file .mednafen/mednafen.cfg

	# byobu
	deploy_file .byobu/keybindings.tmux

	# lagrange (prefs only, no private keys)
	deploy_folder .config/lagrange/fonts
	deploy_file .config/lagrange/prefs.cfg

	# Zettlr
	deploy_folder .config/Zettlr/snippets
	for R in .config/Zettlr/config.json .config/Zettlr/custom.css .config/Zettlr/tags.json .config/Zettlr/user.dic; do
		deploy_file "$R"
	done

	# WindowMaker
	deploy_file GNUstep/Library/WindowMaker/Themes/GruvBox.style
	for R in GNUstep/Defaults/WindowMaker GNUstep/Defaults/WMState; do
		deploy_file "$R"
	done

	# scite french locale (system-wide, needs sudo)
	printf "Now this script can install french locale properties for scite in /usr/share/scite/ (using sudo). Do you agree? (y/n)"
	read -r answ4
	if [[ "$answ4" == "y" ]]; then
		sudo cp .scite/locale.fr.properties /usr/share/scite/
		printf "Done.\n"
	else
		printf "Nothing was changed.\n"
	fi
}


#apt-mini
#apt-extra
deploy_dotfiles
