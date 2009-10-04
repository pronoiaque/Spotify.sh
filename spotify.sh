#!/bin/bash
###
### Under GPL v2 - pronoiaque@gmail.com
### thx aidos
###
### Variables et lancement de Spotify
###
declare -i volume
declare -i tagueule

tagueule=0
user=`whoami`

###################################
###  On récupère la liste des Pubs
###
### ( Merci de me signaler s'il manque des pubs, si possible avec leur titre )
###
if [ $1 ] ; then
	pubpatterns=$(wget -O - "`echo $1`" 2>/dev/null)
  else
	pubpatterns=$(wget -O - http://github.com/pronoiaque/Spotify.sh/raw/master/spotify.pub 2>/dev/null)

fi

##################################################################"
### Est-ce que les packages necessaires sont installés ?

if [ ! -x /usr/bin/wmctrl ] ; then
        zenity --question --text "Le package <b>wmctrl</b> n'est pas detecté.\nVoulez-vous l'installer ?"
        if [ $? == "0" ] ; then
                gksudo aptitude install wmctrl
        fi
fi

if [ ! -x /usr/bin/amixer ] ; then
        zenity --question --text "Le package <b>alsa-utils</b> n'est pas detecté.\nVoulez-vous l'installer ?"
        if [ $? == "0" ] ; then
                gksudo aptitude install alsa-utils
        fi
fi

####################################
### On lance Spotify, avant toute chose
###
env WINEPREFIX="/home/$user/.wine" wine 2>/dev/null "C:\Program Files\Spotify\spotify.exe"&


########################################
### On crée un fonction qui détecte le titre de la fenêtre Spotify
### et qui crée un "ads" non NULL si un pub est détectée

function grab_titre
{
	titre=$(echo `wmctrl -l | grep Spotify | cut -d" " -f 5-500`)
	ads=$(echo `echo $titre | grep -iE "$pubpatterns"`)
}

######################################
###  Une pour recuperer les valeurs du volume (Master + PCM ) de l'utilisateur
###
function get_user_vol
{
	VolMaster=`amixer -c 0 cget name='Master Playback Volume' | grep : | sed 's/^.*=\([^,]*\).*$/\1/'`
	VolPCM=`amixer -c 0 cget name='PCM Playback Volume' | grep : | sed 's/^.*=\([^,]*\).*$/\1/'`
}

################################################
### Pour les reinjecter après une pub
function put_user_vol
{
	amixer -q cset name='Master Playback Volume' $VolMaster
	amixer -q cset name='PCM Playback Volume' $VolPCM
}

#############################################
### Pour Regler le Mixer PCM à une certain valeur
###
function setvolume
{
	amixer -c 0 cset name='PCM Playback Volume' $1 1>/dev/null
}

###########################################
### le Volume PCM sert de 1 niveau
###
get_user_vol
volume=$VolPCM

###################################################
### Début de la Boucle - temps que Spotify tourne
while [ ! "`ps x | grep spotify.exe | grep -v grep`"  = "" ] ;
  do

	###############################
	## Recuperation titre et volume
	##
	grab_titre

	##############################################################################
	### Si une pub en PLAY est detectée avec un volume fort
	### - On baisse le volume au mininum -> Mise en PAUSE
	### - Ajout d'un trigger (ferme) "tagueule"

	if [ ! "$ads" = "" ] && [ ! "$titre" = "Spotify" ] && [ $volume -gt 7 ] ; then
		volume=1
		setvolume $volume
		sleep 0.4
		tagueule=1
		grab_titre
	fi

	#####################################################
	### Si Spotify est en PAUSE + trigger
	### - On augmente le volume jusqu`à la mise en PLAY
	###
	while [ "$titre" = "Spotify" ] && [ $tagueule = 1 ] ;
	 do
		volume=$((`echo $volume` + 3))
		setvolume $volume
		sleep 0.5
		grab_titre
	done

	##################################################################################################
	## Si la pub est en PLAY à un volume reduit
	## - On la laisse tourner
	##
	while [ ! "$ads" = "" ] && [ ! "$titre" = "Spotify" ] && [ $tagueule = 1 ] && [ $volume -le 7 ] ;
	 do
		grab_titre
		sleep 0.5
	done

	###############################################
	## S'il n'y a plus de pub
	## - On remets le

	if [ "$ads" = "" ] && [ $tagueule = 1 ] ; then
		put_user_vol
		tagueule=0
	fi

	################################
	## Recuperation du Volume
	##
	if [ $tagueule = 0 ] ; then
		get_user_vol
		volume=$VolPCM
	fi

	sleep 0.2
done
exit 0
