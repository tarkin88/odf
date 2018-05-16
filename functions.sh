#!/usr/bin/bash
# |------------------------------------------|
# |         Author: Francisco Suárez         |
# |            github: tarkin88              |
# |                May 2018                  |
# |  Some functions come from Helmuthdu Aui  |
# |            github: helmuthdu             |
# |------------------------------------------|

delete_all() {
	if  [[ -d "${1}" ]]; then
		rm -R ${1}
	fi
}

read_input() {
	#read -p "$prompt1" OPTION
	read -p "$1: " OPTION
    echo ""
    OPTION=`echo "$OPTION" | tr '[:upper:]' '[:lower:]'`
}

read_input_text() { 
    read -p "$1 [y/N]: " OPTION
    echo ""
    OPTION=`echo "$OPTION" | tr '[:upper:]' '[:lower:]'`
} 

print_line() { 
    printf "${WHITE}%$(tput cols)s\n\n"| tr ' ' '-'
}

pause_function() { 
    print_line
    read -e -sn 1 -p "Press enter to continue..."
}

replace_line() { 
    local _search=${1}
    local _replace=${2}
    local _filepath=${3}
    local _filebase=`basename ${3}`

    sed -e "s/${_search}/${_replace}/" ${_filepath} > /tmp/${_filebase} 2>"$LOG"
    if [[ ${?} -eq 0 ]]; then
      mv /tmp/${_filebase} ${_filepath}
    else
      echo -e "failed: ${_search} - ${_filepath}"
    fi
} 

add_top() {
	sed -i "1 i\
	${1}" ${2}
}

infect_vim() {
	if  [ ! -d ~/.vim/autoload ]; then
		mkdir -p ~/.vim/autoload ~/.vim/bundle && \
		curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
		echo -e "${GREEN}[*] Pathogen  (vim) Installed"
		git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree
		echo -e "${GREEN}[*] Nerd Tree (vim) Installed"
		git clone https://github.com/ctrlpvim/ctrlp.vim.git ~/.vim/bundle/ctrlp.vim
		echo -e "${GREEN}[*] Ctrl P (vim) Installed"

	else
		echo -e "${GREEN}[*] Pathogen  (vim) already exist"
		echo -e "${GREEN}[*] Nerd Tree  (vim) already exist${WHITE}"
		echo -e "${GREEN}[*] Ctrl P (vim) already exist${WHITE}"
	fi
}

seek_and_destroy() {
	if  [[ -d "${1}" ]]; then
		delete_all ${1}
		echo -e "${YELLOW}[-] ${1} Cleaned"
	elif [[ -f "${1}"  ]]; then
		delete_all ${1}
		echo -e "${YELLOW}[-] ${1} Cleaned"
	fi
}

set_permissions() {
	declare -a FILES=$(ls ${1})
	for f in $FILES;
	do	
		chmod +x ${1}/${f}
		echo -e "${GREEN}[*] ${f} Permission Applied"
	done
	echo -e "${WHITE}"
}

if_not_create() {
	if  [ ! -d "${1}" ]; then
		mkdir -p ${1}
		echo -e "${YELLOW}[-] ${1} Created"
	fi	
}

xrdb_reload() {
	xrdb ${HOME}/.Xresources
	echo -e "${GREEN}[*] X resources reloaded\n ${WHITE}"
}

copy_files() {
	declare -a FILES=$(ls ${1})
	for f in $FILES;
	do	
		if [[ ${3} -eq 1 ]]; then
			seek_and_destroy "${2}/.${f}"	
			if_not_create ${2}
			cp -R "./${1}/${f}" "${2}/.${f}"
		else
			seek_and_destroy "${2}/${f}"
			if_not_create ${2}
			cp -R "./${1}/${f}" ${2}
		fi
		echo -e "${GREEN}[*] ${f} Copied"
	done
	echo -e "${WHITE}"
}

copy_dots() {	
	copy_files "dots/config" ${configPath} 0
	copy_files "dots/home" ${HOME} 1
	copy_files "bin" ${binPath} 0
	set_permissions ${configPath}/polybar/modules/
	configure_devices
}

welcome() {
	echo -e "\n${WHITE} Welcome!"
	echo -e "\n${WHITE} This script generate many dots\n"
	print_line
	echo -e "${CYAN} PACKAGES${WHITE}\n"
	print_line
}

info(){
	echo -e "\n${YELLOW}Here some info about your system:\n"
	echo -e "* ${YELLOW}You have ${WHITE}$(sudo pacman -Q|wc -l) ${YELLOW}Installed\n"
	echo -e "* ${YELLOW}Running under ${WHITE}$(uname -r) ${YELLOW} Kernel\n"
	echo -e "* ${YELLOW}On ${WHITE}$(cat /etc/os-release | grep 'PRETTY_NAME' | cut -d '=' -f2 | cut -d '"' -f2)\n"

	pause_function
}

is_installed() {
    package="$1";
    check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")";
    if [ -n "${check}" ] ; then
        echo 1; #'1' means 'true' in Bash
        return; #true
    fi;
    echo 0; #'0' means 'false' in Bash
    return; #false
}

install_from_list() {
	echo -e "${GREEN}[ ] Check for no installed packages \n ${WHITE}"
	declare -a to_install=()
	for package in `cat $packagesList`;
	do
		 if [[ $(is_installed "${package}") == 0 ]]; then
			to_install+=(${package})
	        continue;
    	fi;
	done

	sudo pacman -Sy ${to_install}
	echo -e "${GREEN}[*] Packages installed \n ${WHITE}"
}

install_from_aur() {
	echo -e "${GREEN}[ ] Check for no installed packages \n ${WHITE}"
	declare -a to_install=()
	for package in `cat $aurPackagesList`;
	do
		 if [[ $(is_installed "${package}") == 0 ]]; then
			to_install+=(${package})
	        continue;
    	fi;
	done

	yaourt -Sy ${to_install} --noconfirm
	echo -e "${GREEN}[*] Packages installed \n ${WHITE}"
}

set_pip_alias() {
	ALIAS="alias yy=\"mpv --really-quiet --volume=50 --autofit=30% --geometry=-10-15 --ytdl --ytdl-format='mp4[height<=?720]' -ytdl-raw-options=playlist-start=1\""
	grep -q -F "${ALIAS}" ${HOME}/.zshrc || echo "${ALIAS}" >> ${HOME}/.zshrc
	echo -e "${GREEN}[*] PiP(Picture in Picture) set as Alias -> 'yy' \n ${WHITE}"
}

set_colors() {

	case ${1} in
		0)
			replace_line "BACKGROUND" "set \$backgr ${2}" ${configPath}/i3/config				
			replace_line "#2A363B" "${2}" ${HOME}/.xrdb/color/theme
			replace_line "COLOR_BACKGROUND" "\"${2}\"" ${configPath}/dunst/dunstrc
			;;
		1)

			replace_line "FOREGROUND" "set \$foregr ${2}" ${configPath}/i3/config	
			replace_line "#E8DFD6" "${2}" ${HOME}/.xrdb/color/theme				
			;;
		2)
			replace_line "ACCENT" "set \$accent ${2}" ${configPath}/i3/config	
			replace_line "FCOLOR" "F${2}" ${binPath}/toggle.sh		
			replace_line "FCOLOR" "F${2}" ${binPath}/spotify-info.sh
			replace_line "#2E3340" "${2}" ${HOME}/.xrdb/color/theme				
			;;
		3)
			replace_line "URGENT" "set \$urgent ${1}" ${configPath}/i3/config	
			;;
	esac
}

ask_themes(){
	echo -e "${WHITE}"
	read_input_text "Do you want apply a custom theme?(check variables.sh)"
	if [[ $OPTION == y ]]; then
		for index in "${!navy_n_ivory_schema[@]}"; do
			set_colors $index ${navy_n_ivory_schema[$index]}
		done
			echo -e "${GREEN}[*] Theme i3 Applied \n ${WHITE}"
			echo -e "${GREEN}[*] Theme Polybar Applied \n ${WHITE}"
			echo -e "${GREEN}[*] Theme Terminal Applied \n ${WHITE}"
	else 
		echo -e "${YELLOW}[-] Passed${WHITE}\n"
		for index in "${!default_schema[@]}"; do
			set_colors $index ${default_schema[$index]}
		done
	fi
}

set_monitor_variable() {
	MONITOR=$(xrandr -q | grep " connected" | cut -d ' ' -f1)
}

apply_antigen() {
	if  [ ! -f "${HOME}/antigen.zsh" ]; then
		curl -L git.io/antigen > ${HOME}/antigen.zsh
	fi	
	copy_files "dots/antigen" ${HOME} 1
	echo -e "${GREEN}[*] Antigen applied ${WHITE}\n"
}

ask_pathogen() {
	read_input_text "Do you want use vim pathogen?"
	if [[ $OPTION == y ]]; then
		infect_vim
		add_top ":helptags ~/.vim/bundle/ctrlp.vim/doc" ~/.vimrc
		add_top "set runtimepath^=~/.vim/bundle/ctrlp.vim" ~/.vimrc
		add_top "map <C-l> :NERDTreeToggle<CR>" ~/.vimrc
		add_top "autocmd StdinReadPre * let s:std_in=1" ~/.vimrc
		add_top "autocmd VimEnter * if argc() == 0 && !exists(\"s:std_in\") | NERDTree | endif" ~/.vimrc
		add_top "execute pathogen#infect()" ~/.vimrc
		echo -e "\n"
	else 
		echo -e "${YELLOW}[-] Passed${WHITE}\n"
	fi

}
ask_dots() {
	print_line
	echo -e "${CYAN} DOT FILES${WHITE}\n"
	print_line
	read_input_text "Do you generate dots files?"
	if [[ $OPTION == y ]]; then
		copy_dots
		ask_themes
		ask_zsh
		ask_pathogen
		set_pip_alias
		xrdb_reload
		set_permissions ${binPath}
	else 
		echo -e "${YELLOW}[-] Passed${WHITE}\n"
	fi
}

ask_packages() {
	read_input_text "Do you want install extra packages on packages.txt?"
	if [[ $OPTION == y ]]; then
		info
		install_from_list
	else 
		echo -e "${YELLOW}[-] Passed${WHITE}\n"
	fi

	read_input_text "Do you want install aur packages on aur_packages.txt?"
	if [[ $OPTION == y ]]; then
		install_from_aur
	else 
		echo -e "${YELLOW}[-] Passed${WHITE}\n"
	fi
}

ask_zsh() {
	read_input_text "Do you use zsh (Z shell)?"
	if [[ $OPTION == y ]]; then
		read_input_text "Do you want to use antigen?"
		if [[ $OPTION == y ]]; then
			apply_antigen
		else 
			echo -e "${YELLOW}[-] Passed${WHITE}\n"
		fi
	else 
		echo -e "${YELLOW}[-] Passed${WHITE}\n"
	fi
}

configure_devices() {
	set_monitor_variable

	echo -e "${YELLOW}[-] Check Network interface"
	replace_line "interface = INTERFACE" "interface = ${IW}" ${configPath}/polybar/modules.conf		
	echo -e "${GREEN}[*] Network interface Applied\n ${WHITE}"

	echo -e "${YELLOW}[-] Check Monitor Device"
	replace_line "monitor = MONITOR" "monitor = ${MONITOR}" ${configPath}/polybar/config		
	echo -e "${GREEN}[*] Monitor Device layout Applied\n ${WHITE}"

	echo -e "${YELLOW}[-] Check Battery device"
	if [ -d /sys/class/power_supply/BAT* ]; then
		BAT=$(ls /sys/class/power_supply/ | grep 'BAT')
		replace_line "battery = BAT1" "battery = ${BAT}" ${configPath}/polybar/modules.conf		
		replace_line "MODULES_RIGHT" "modules-right  = pkg toggle_xautlock memory coreuse wireless-network volume battery" ${configPath}/polybar/config		
		echo -e "${GREEN}[*] Battery configuration Applied\n ${WHITE}"
	else
		replace_line "MODULES_RIGHT" "modules-right  = pkg toggle_xautlock memory coreuse wireless-network volume" ${configPath}/polybar/config		
	fi
}

say_goodbye() {
	END_MESSAGE="That's all [^_^]/"

	echo -e "\n${CYAN}${END_MESSAGE}\n\n"

	if ! pgrep "dunst" >/dev/null 2>&1 ; then
		dunst &
	fi
	notify-send DFG "${END_MESSAGE}" -t 0

	exit 0
}

reload_all() {
	${binPath}/launch_polybar.sh
}