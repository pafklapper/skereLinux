#/bin/sh

# bash run options
set -o pipefail

initVars()
{
installationDirectory="$(dirname $(realpath "$0"))"
. $installationDirectory/globalVariables
. $installationDirectory/globalFunctions
logFile=/var/log/skLinux.log
}

main()
{
initVars;cd $installationDirectory

clear
logp beginsection
logp info  "wachten op de netwerkverbinding... " && waitForNetwork


mountEnv=""
# check which platform 
if [ -n "$(mount | grep "${targetDisk}2 on / type" )" ]; then
	# dit is de beheer partitie
	mountEnv="be"
elif [ -n "$(mount | grep "${targetDisk}3 on / type")" ];then
	# dit is SLICE A
	if [ -f /install-date ]; then
		mountEnv="A"
	fi
elif [ -n "$(mount | grep "${targetDisk}4 on / type")" ];then
	# dit is SLICE B
	if [ -f /install-date ]; then
		mountEnv="B"
	fi
fi

# update
if ! isGitRepoUptodate;then
	git pull

	#run update magic
fi

# check if this is an install env


if [ "$mountEnv" = "be" ]; then
	logp info "BEHEER omgeving geladen.."

	if mount ${targetDisk}3 /mnt/SLICE-A && [ -f /mnt/SLICE-A/install-date ] && mount ${targetDisk}4 /mnt/SLICE-B && [ -f /mnt/SLICE-B/install-date ]; then
		logp info "SLICES succesvol gemount.."
	else
		if [ -f /skLinuxGoooo ]; then
			logp info "Installatie zal worden hervat!"
			if cat /dev/null > /srv/skLinux/stage1.runner && sh $installationDirectory/stage1.sh; then
				rm -f /skLinuxGoooo
				logp endsection
				logp info "Installatie succesvol! De computer is nu klaar voor gebruik en zal over vijf seconde vanzelf opnieuw opstarten!"
				sleep 5 reboot
			else
				logp fatal "Installatie helaas mislukt! :("
			fi
		fi
	fi
elif [ "$mountEnv" = "A" ]; then
	logp info "SLICE-A omgeving geladen.."
elif [ "$mountEnv" = "B" ]; then
	logp info "SLICE-B omgeving geladen.."
else
	logp info "USBINSTALL omgeving geladen.."
	logp info "Installatie zal worden gestart.."
	if cat /dev/null > /srv/skLinux/stage0.runner && sh $installationDirectory/stage0.sh; then
		logp endsection
		logp info "Installatie succesvol! Druk op een knop om de computer opnieuw op te starten en verder te gaan met de installatie!"
		read; reboot
	else
		logp fatal "Installatie helaas mislukt! :("
	fi
fi

}
main $@
