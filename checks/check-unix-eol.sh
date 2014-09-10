#!/bin/bash
#
# Ce script permet de vérifier que des fichiers textes ont bien des fin de ligne unix
#
# Code de retour :
# 0 si tout va bien
# 1 si au moins un fichier ne semble pas encodé correctement (la liste des fichiers est écrit sur la sortie standard)
# 2 en cas d'autres erreurs (usage...)

function usage()
{
	echo "Analyse les fichiers de toute une arborescence (en recursif donc) pour vérifier qu'ils ont bien des fins de ligne unix."
	echo
    echo "Usage : $0 directory [extension extension extension ...]"
	echo "Où : "
	echo "  directory est le répertoire à analyser (récursivement)."
	echo "  extension sont les extensions des fichiers à tester. Si aucune extension n'est fournie, tous les fichiers du répertoire seront testés."
    echo "Exemple : $0 . php"
}

# Vérification du nombre de paramètres
if [ $# -lt 1 ]; then
    usage
    exit 2
fi

DIRECTORY=$1
shift;

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
		FILES=$(find $DIRECTORY -not -path '*/\.*' -type f | grep -E "$FILTER" | grep -v -E "$EXCLUDE_FILTER")
	else
		FILES=$(find $DIRECTORY -not -path '*/\.*' -type f | grep -E "$FILTER")
	fi
else
	FILES=$(find $DIRECTORY -not -path '*/\.*' -type f)
fi

RESULT=""
if [ -n "$FILES" ] ; then
	for f in $FILES ; do
		if awk  '/\r$/{exit 0;} 1{exit 1;}' $f ; then
			RESULT=$RESULT"$f\n"
		fi
	done
fi

if [ -n "$RESULT" ] ; then
	echo "Les fichiers suivants ne semblent pas être au format Unix :"
	echo -e "$RESULT"
	exit 1
fi

