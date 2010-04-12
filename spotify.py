#!/bin/python
# -*- coding:Utf-8 -*-
###############################################################
### Quelques ingrédiants de base, pour cette drole de Cuisine
import os, commands, re, sys, time, types


###############################################################
### Ben, "chantez maintenant !" 

def launch_spotify():
	os.system("wine 2>/dev/null 'C:\Program Files\Spotify\spotify.exe'&")
#launch_spotify()


###############################################################
### Recup ID XWindow de la fenetre Wine / Spotify

def spotify_window_id():
	for title in commands.getoutput("xwininfo -root -tree").split("\n"):
		if (re.search('spotify.exe',title)) and not (re.search('has no name',title)):
			return title.split()


################################################################
### Recup le titre de spotify, require l'ID de la bonne fenetre

def title_spotify_window():
	return commands.getoutput("xprop -id %s WM_NAME" % id).split("\"")[1]


###############################################################
### Recup des Volumes utilisateur 
### ! => Dynamique  

def get_user_vol():
	Master = commands.getoutput("amixer -c 0 -D hw:0 cget name='Master Playback Volume'").split("\n")[2].split("=")[1]
	PCM = commands.getoutput("amixer -c 0 -D hw:0 cget name='PCM Playback Volume'").split("\n")[2].split(",")[1]
	return [Master,PCM]


###############################################################
### Remets les volumes utilisateur

def put_user_vol(Master,PCM):
	os.system("amixer -q -D hw:0 cset name='Master Playback Volume' %s" % Master)
	os.system("amixer -q -D hw:0 cset name='PCM Playback Volume' %s" % PCM) 


###############################################################
## Mets un Volume à une valeur

def set_vol(vol):
        os.system("amixer -c 0 -D hw:0 cset name='PCM Playback Volume' %s 1>/dev/null " % vol)


#######################################################################
### Attends Win Spotify pour affecter du bon ID XWindows

while type(spotify_window_id()) == types.NoneType:
	time.sleep(0.05)
id = spotify_window_id()[0]

###############################################################
### le Volume PCM sert de niveau de reference
voluser = get_user_vol()[1]
volume = voluser
##############################################################
### Tant que Spotify fonctionne
while type(spotify_window_id()) == types.ListType: 
	title = title_spotify_window()
	time.sleep(0.2)
	if title != title_spotify_window():
		print "changement de titre"
		set_vol(0)
		time.sleep(0.2)
		if "Spotify" != title_spotify_window():
			print "remise niveau"
			set_vol(voluser)
		else:
			print "arhh une pub !!" 
			shutup = 1
			volume = 0
			while shutup == 1:
				volume = 0 
				set_vol(volume)
				while "Spotify" == title_spotify_window():
					volume = volume + 1
					set_vol(volume)
					time.sleep(0.5)
				if "Spotify" != title_spotify_window() and volume < 7:
					shutup = 0
						
	else:
		print "circulez !!"



#VolMaster,VolPCM = get_user_vol()[0]
#VolPCM = get_user_vol()[1]
#print VolMaster + " " + VolPCM
	



#print title_spotify_window()


#get_spotify_window_id()

#if type(get_spotify_window_id()) == types.ListType:
#	print "spotify active"

#if type(get_spotify_window_id()) == types.NoneType:
#	print "spotify off"


