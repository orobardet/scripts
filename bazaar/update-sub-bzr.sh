#!/bin/bash

SCRIPTNAME=$(basename $0)

function usage()
{
    echo "Usage : $SCRIPTNAME [<repo dir>] "
    echo "Si le répertoire <repo dir> (ou du répertoire courant si <repo dir> omis) est un dépôt Bazaar, y effectue un bzr update."
    echo "Sinon scan tous les sous répertoire de <repo dir> (ou du répertoire courant si <repo dir> omis), et effectue un bzr update dans tous ceux qui contiennent un .bzr."
    echo "Exemple : $SCRIPTNAME "
    echo "          $SCRIPTNAME ~/kebzr/mpp"
}

function update_depot()
{
    DEPOT_DIR="$1"
    if [ "$DEPOT_DIR" ]; then
        bzr update $DEPOT_DIR/
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
        echo -e "\\033[1;33mUpdate du dépôt $BZR_DIR\\033[0;0m"
        update_depot $BZR_DIR
    else
        echo -e "\\033[1;33mUpdate des dépôts dans $BZR_DIR\\033[0;0m"
        for i in $(ls $BZR_DIR); do
            if [ -d "$BZR_DIR/$i" ] ; then
                if [ -d "$BZR_DIR/$i/.bzr" ] ; then
                    echo ""
                    echo -e "\\033[1;36m:: Update de $i...\\033[0;0m"
                    update_depot $BZR_DIR/$i
                fi
            fi
        done
    fi
else
    echo "$BZR_DIR n'est pas un répertoire existant"
fi