#!/bin/sh
#
# Ce script permet de vérifier que l'encodage de fichiers (page de code type utf8, ansi...) non binaire est correct.
# Necessite iconv !
#
# Code de retour :
# 0 si tout va bien
# 1 si au moins un fichier ne semble pas encodé correctement (la liste des fichiers est écrit sur la sortie standard)
# 2 en cas d'autres erreurs (usage...)

function usage()
{
	echo "Analyse les fichiers de toute une arborescence (en recursif donc) pour vérifier que leur encodage est correct."
	echo
    echo "Usage : $0 encoding directory [extension extension extension ...]"
	echo "Où : "
	echo "  encoding est l'encodage à vérifier (par ex 'utf-8'). Ce doit être un format reconnu par iconv."
	echo "  directory est le répertoire à analyser."
	echo "  extension sont les extensions des fichiers à tester. Si aucune extension n'est fournie, tous les fichiers du répertoire seront testés."
    echo "Exemple : $0 utf-8 . php"
    echo "          $0 ~/kebuild/mpp RC1"
}

function check_command()
{
	if type $1 &> /dev/null; then
		echo 1
	else
		echo 0
	fi
}

# On vérifie la présence d'iconv, qui est nécessaire pour le fonctionnement du script
if [ ! $(check_command iconv) -eq 1 ]; then
	echo "*** iconv est nécessaire pour ce script"
	exit 2
fi

# Vérification du nombre de paramètres
if [ $# -lt 2 ]; then
    usage
    exit 2
fi

ENCODING=$1
DIRECTORY=$2
shift ; shift;

FILTER=""
HAS_FILTER=0
if [ $# -gt 0 ]; then
	HAS_FILTER=1
	FILTER="\.("
	while [ $# -gt 0 ]; do
		FILTER="$FILTER$1"
		shift
		if [ $# -gt 0 ]; then FILTER="$FILTER|"; fi
	done
	FILTER="$FILTER)\$"
fi

EXCLUDE_FILTER=""
HAS_EXCLUDE=0
BZR_IGNORED=$(bzr ls $DIRECTORY --ignored 2>/dev/null)
if [ -n "$BZR_IGNORED" ] ; then
	HAS_EXCLUDE=1
	for IGN in $BZR_IGNORED ; do
		EXCLUDE_FILTER="$EXCLUDE_FILTER$IGN|"
	done
	EXCLUDE_FILTER=$(echo $EXCLUDE_FILTER | sed 's/|$//')
fi

if [ $HAS_FILTER -eq 1 ] ; then
	if [ $HAS_EXCLUDE -eq 1 ] ; then
		RESULT=$(find $DIRECTORY -type f | grep -E "$FILTER" | grep -v -E "$EXCLUDE_FILTER" | xargs -I {} bash -c "iconv -f $ENCODING -t utf-16 {} &>/dev/null || echo {}")
	else
		RESULT=$(find $DIRECTORY -type f | grep -E "$FILTER" | xargs -I {} bash -c "iconv -f $ENCODING -t utf-16 {} &>/dev/null || echo {}")
	fi
else
	RESULT=$(find $DIRECTORY -type f | xargs -I {} bash -c "iconv -f $ENCODING -t utf-16 {} &>/dev/null || echo {}")
fi
if [ -n "$RESULT" ] ; then
	echo "Les fichiers suivants ne semblent pas correctement encodés en $ENCODING :"
	echo -e "$RESULT"
	exit 1
fi
