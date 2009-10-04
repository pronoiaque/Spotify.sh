#!/bin/bash
###
### Under GPL v2 - pronoiaque@gmail.com
### thx aidos
###
### Variables et lancement de Spotify
###
declare -i volume
declare -i tagueule
declare -i adsurl

pubpatterns=$(wget -O - http://github.com/pronoiaque/Spotify.sh/raw/master/spotify.pub 2>/dev/null)
tagueule=""
user=`whoami`

env WINEPREFIX="/home/$user/.wine" wine 2>/dev/null "C:\Program Files\Spotify\spotify.exe"&



###################################
###  On récupère la liste des Pubs
###
### ( Merci de me signaler s'il manque des pubs, si possible avec leur titre )
###
if [ $1 ] ; then
	echo $1
	pubpatterns=$(wget -O - "`echo $1`" 2>/dev/null)
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

`$WINEPREFIX`




########################################
### On crée un fonction qui détecte le titre de la fenêtre Spotify
### et qui crée un "tilt" si un pub est détectée

function grab_titre
{
	titre=$(echo `wmctrl -l | grep Spotify | cut -d" " -f 5-500`)
	tilt=$(echo `echo $titre | grep -iE "$pubpatterns"`)
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

       #########################################
       #### Pour le cas de la première pub détectée
       ####
    if [ ! "$tilt" = "" ] && [ ! "$titre" = "Spotify" ] && [ $volume -gt 5 ] ; then
        volume=1
        setvolume $volume 2>/dev/null
        sleep 0.5
        tagueule=1
        grab_titre
    fi


        ##########################################################
        #### Si une pub est détectée et qu'elle est mise en pause à cause de la baisse du volume
        #### - On remonte de deux crans et si elle n'est plus en pause, on la laisse se diffuser (sleep 5)

    while [ "$titre" = "Spotify" ] && [ $volume -lt $VolPCM ] && [ $tagueule = 1 ] ;
     do
        volume=volume+2
        setvolume $volume 2>/dev/null
        grab_titre
        if [ ! "$titre" = "Spotify" ] ; then
             sleep 5
          else
            sleep 0.2
        fi
    done

        ###########################################################
        ###
        ###

    while [ ! "$tilt" = "" ] && [ ! "$titre" = "Spotify" ] && [ $tagueule = 1 ] && [ $volume -gt 5 ] ;
     do
        volume=1
        setvolume $volume 2>/dev/null
        sleep 0.2
        grab_titre
    done



    ##############################################################
    ### Si il n'y a pas de pub, pas de pause et le son même légèrement baissé
    ### - on remonte le son au niveau du volume de l'utilisateur
    ###

    if  [ "$tilt" = "" ] && [ ! "$titre" = "Spotify" ] && [ $volume -lt $VolPCM ] ; then
        put_user_vol
        tagueule=""
	echo  "put user vol"
    fi

    ################################################################
    ## Pour pas bouffer toutes les ressources avec la boucle
    ## - On en profite pour check le volume choisi par l'utilisateur
    ##
    if [ "$tilt" = "" ] && [ ! "$titre" = "Spotify" ] && [ $volume -ge $VolPCM ] ; then
        sleep 0.2
        get_user_vol
   fi

  sleep 0.2

done
exit 0
