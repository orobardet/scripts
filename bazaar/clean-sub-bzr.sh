#!/bin/sh

SCRIPTNAME=$(basename $0)

function usage()
{
    echo "Usage : $SCRIPTNAME [<repo dir>] "
    echo "Si le répertoire <repo dir> (ou du répertoire courant si <repo dir> omis) est un dépôt Bazaar, le nettoie."
    echo "Sinon scan tous les sous répertoire de <repo dir> (ou du répertoire courant si <repo dir> omis), et nettoie ceux qui correpondent à un dépôt Bazaar."
    echo "Le nettoyage consiste en une suppression de tous les fichiers ignorés par Bazaar (bzr clean-tree --ignored)."
    echo "Exemple : $SCRIPTNAME "
    echo "          $SCRIPTNAME ~/kebzr/mpp"
}

function clean_depot()
{
    DEPOT_DIR="$1"
    if [ "$DEPOT_DIR" ]; then
        $(cd $DEPOT_DIR ; bzr clean-tree --ignored --force)
    fi
}

BZR_DIR=$(pwd)

while [ $# -gt 0 ] ; do
      case "$1" in
          --help|-h) shift ; usage ; exit 0 ; break ;;
          *) BZR_DIR=$1 ; shift ; break ;;
          # plus de parametre -> sortie
          --) shift ; break ;;
      esac
done

if [ -d "$BZR_DIR" ] ; then
    if [ -d "$BZR_DIR/.bzr" ] ; then
        echo -e "\\033[1;33mNettoyage du dépôt $BZR_DIR\\033[0;0m"
        clean_depot $BZR_DIR
    else
        echo -e "\\033[1;33mNettoyage des dépôts dans $BZR_DIR\\033[0;0m"
        for i in $(ls $BZR_DIR); do
            if [ -d "$BZR_DIR/$i" ] ; then
                if [ -d "$BZR_DIR/$i/.bzr" ] ; then
                    echo ""
                    echo -e "\\033[1;36m:: Update de $i...\\033[0;0m"
                    clean_depot $BZR_DIR/$i
                fi
            fi
        done
    fi
else
    echo "$BZR_DIR n'est pas un répertoire existant"
fi