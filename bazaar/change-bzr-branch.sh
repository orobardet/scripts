#!/bin/bash

SCRIPTNAME=$(basename $0)

function usage()
{
    echo "Usage : $SCRIPTNAME <branch> "
    echo "Change la branche bazaar du répertoire courant par <branch>, sans merge (différent du switch)."
    echo "Si le répertoire courant est un dépôt Bazaar :"
    echo " - Vérifie qu'il n'y a pas d'élément non commités, et si oui demande confirmation de continuer"
    echo " - Supprime l'intégralité du contenu du répertoire courant"
    echo " - Effectue un bzr checkout de <branch> dans le répertoire courant"
    echo "Exemple : $SCRIPTNAME mel:712-ols-tools/dev_evol1"
}

function check_depot()
{
    DEPOT_DIR="$1"
    if [ "$DEPOT_DIR" ]; then
        BRANCH_LOCATION=$(bzr info $DEPOT_DIR/ | grep "checkout of branch" | sed 's/^.*checkout of branch:[ \t]*//')
        BRANCH=$(echo "$BRANCH_LOCATION" | sed 's/^.*bzrroot\/[^/]*//')
        STATUS=$(bzr status $BZR_OPT $DEPOT_DIR/)
        MISSING=$(cd $DEPOT_DIR/ ; bzr missing --line "$BRANCH_LOCATION" 2>/dev/null)
        if [ $? -eq 1 ] ; then
            NOT_UP_TO_DATE=1
        else
            NOT_UP_TO_DATE=0
        fi
        
        echo -en " Branche : $BRANCH - "
        if [ "$STATUS" ] ; then
            if [ $NOT_UP_TO_DATE -eq 1 ] ; then
                echo -e "\\033[1;31mChangements détectés :\\033[0;0m"
                echo -e "$STATUS"
                echo -e "\\033[1;31mPas la dernière révision :\\033[0;0m"
                echo -e "$MISSING"
            else
                echo -e "\\033[1;32mA jour\\033[0;0m - \\033[1;31mChangements détectés :\\033[0;0m"
                echo -e "$STATUS\n"
            fi
        else
            if [ $NOT_UP_TO_DATE -eq 1 ] ; then
                echo -e "\\033[1;32mPas de changements détectés\\033[0;0m - \\033[1;31mPas la dernière révision :\\033[0;0m"
                echo -e "$MISSING"
            else
                echo -e "\\033[1;32mPas de changements détectés\\033[0;0m - \\033[1;32mA jour\\033[0;0m"
            fi
        fi
    fi
}

if [ $# -lt 1 ] ; then
    usage
    exit 1
fi

BZR_DIR=$(bzr root)
BRANCH=$1

# On vérifie que la branche demandée existe
echo -e "\\033[1;33mVérification de la branche $BRANCH...\\033[0;0m"
RESULT_LD=$(bzr ls $BRANCH 2>/dev/null)
if [ $? -ne 0 ] ; then
    echo -e "\\033[1;31mLa branche $BRANCH n'existe pas.\\033[0;0m"
    exit 2
fi

if [ -d "$BZR_DIR" ] ; then
    if [ -d "$BZR_DIR/.bzr" ] ; then
        CWD=$(pwd)
        cd $BZR_DIR
        
        CAN_CHANGE=0
        echo -e "\\033[1;33mVérification de modifications non commitées...\\033[0;0m"
        STATUS=$(bzr status)
        # Changements détectés, on demande confirmation
        if [ "$STATUS" ] ; then
            echo -e "\\033[1;31mChangements détectés :\\033[0;0m"
            echo -e "$STATUS"
            echo -en "\n\\033[1;36m<O> pour continuer, n'importe quelle autre touche pour arrêter : \\033[0;0m"
            read -s -n1
            echo
            case $REPLY in
               o | O)
               CAN_CHANGE=1
               ;;
               * )
               echo -e "\n\\033[1;31mAbandon\\033[0;0m"
               CAN_CHANGE=0
               ;;
            esac
        else
            echo -e "\\033[1;32mOk, pas de modifications non commitées\\033[0;0m"
            CAN_CHANGE=1
        fi        
        
        if [ $CAN_CHANGE -eq 1 ]; then
            echo -e "\n\\033[1;33mChangement de branche...\\033[0;0m"
#            rm -fr * 2>/dev/null
#            rm -fr .* 2>/dev/null
#            bzr co $BRANCH .
			bzr revert --no-backup
			bzr switch --force $BRANCH 
			bzr update
        fi
    else
        echo "$BZR_DIR n'est pas un dépôt Bazaar."
    fi
else
    echo "$BZR_DIR n'est pas un répertoire existant."
fi
