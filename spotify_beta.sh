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
### et qui crée un "tilt" si un pub est détectée

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
	amixer -c 0 cset name='PCM Playback Volume' $1
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
	grab_titre

	if [ ! "$ads" = "" ] && [ ! "$titre" = "Spotify" ] && [ $volume -gt 5 ] && [ $tagueule = 0 ] ; then
		volume=1
		setvolume $volume 2>/dev/null
		sleep 0.5
		tagueule=1
		grab_titre
		echo "mise en PAUSE"
	fi

	while [ "$titre" = "Spotify" ] && [ $tagueule = 1 ] ;
	 do
		grab_titre
		volume=$((`echo $volume` + 1))
		setvolume $volume 2>/dev/null
		sleep 0.5
		echo "Aumentation +1 du volume, jusquà mise en PLAY"
	done

	while [ ! "$ads" = "" ] && [ ! "$titre" = "Spotify" ] && [ $tagueule = 1 ] && [ $volume -lt 5 ] ;
	 do
		grab_titre
		echo dodo
		sleep 0.5
		if [ $ads = "" ] ; then
			put_user_vol
			tagueule=0
			break
			echo "fin de la pub"
		fi
	done

	if [ "$ads" = "" ] ; then
		sleep 0.2
	fi

done
echo "oups trop loin"
exit 0
