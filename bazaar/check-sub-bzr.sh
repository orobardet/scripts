#!/bin/bash

SCRIPTNAME=$(basename $0)

function usage()
{
    echo "Usage : $SCRIPTNAME [<OPTIONS>] [<repo dir>] "
    echo "Si le répertoire <repo dir> (ou du répertoire courant si <repo dir> omis) est un dépôt Bazaar, y effectue un bzr status pour regarder s'il y a des modifications non commitées, et test si un bzr update est nécessaire."
    echo "Sinon scan tous les sous répertoire de <repo dir> (ou du répertoire courant si <repo dir> omis), et effectue un bzr status pour regarder s'il y a des modifications non commitées, et test si un bzr update est nécessaire."
    echo "";
    echo "Options :"
    echo "  -S | --short Correspond à la même option que pour bzr status : indique d'afficher les différences au format simplifié."
    echo "  -r Mode récursif, ne se contente pas de scanner <repo dir> ou le repertoire courant, en mode recursif le script scan aussi tous les sous-répertoires qui ne sont pas des dépôts Bazaar, sans limite de profondeur. Attention : il n'y a pas de contrôle sur les liens symboliques qui bouclent."
    echo "  -q Mode quiet. N'affichera que les messages indiquant les dépôts non commités ou non à jour."
    echo "  -u Vérifie simplement si les dépôts nécessitent un update."
    echo "  -c Vérifie simplement si les dépôts contiennent des modifications non commitées."
    echo "Exemple : $SCRIPTNAME "
    echo "          $SCRIPTNAME ~/kebzr/mpp"
}

function check_depot()
{
    DEPOT_DIR="$1"
    if [ "$DEPOT_DIR" ]; then
        BRANCH_LOCATION=$(bzr info $DEPOT_DIR/ | grep "checkout of branch" | sed 's/^.*checkout of branch:[ \t]*//')
        BRANCH=$(echo "$BRANCH_LOCATION" | sed 's/^.*bzrroot\/[^/]*//')

        NEEDS_COMMIT=0
        NEEDS_UPDATE=0

        if [ $CHECK_COMMIT -eq 1 ]; then
            STATUS=$(bzr status $BZR_OPT $DEPOT_DIR/)
            if [ "$STATUS" ] ; then
                NEEDS_COMMIT=1
            fi
            
        fi

        if [ $CHECK_UPDATE -eq 1 ]; then
            MISSING=$(cd $DEPOT_DIR/ ; bzr missing --line "$BRANCH_LOCATION" 2>/dev/null)
            if [ $? -eq 1 ] ; then
                NEEDS_UPDATE=1
            fi
        fi
        
        if [ $QUIET -eq 1 ]; then
            if [ $NEEDS_COMMIT -eq 1 ] || [ $NEEDS_UPDATE -eq 1 ]; then
                echo -en "\\033[1;36m:: Dépôt $DEPOT_DIR\\033[0;0m (Branche : $BRANCH) - "
                if [ $NEEDS_COMMIT -eq 1 ] && [ $NEEDS_UPDATE -eq 1 ]; then
                    echo -e "\\033[1;31mPas la dernière révision\\033[0;0m - \\033[1;31mChangements détectés :\\033[0;0m"
                    echo -e "$STATUS"
                elif [ $NEEDS_COMMIT -eq 1 ]; then
                    echo -e "\\033[1;31mChangements détectés :\\033[0;0m"
                    echo -e "$STATUS"                
                elif [ $NEEDS_UPDATE -eq 1 ]; then
                    echo -e "\\033[1;31mPas la dernière révision\\033[0;0m"
                fi
            fi
        else
            echo -en " Branche : $BRANCH - "
            if [ $NEEDS_COMMIT -eq 1 ] ; then
                if [ $NEEDS_UPDATE -eq 1 ] ; then
                    echo -e "\\033[1;31mChangements détectés :\\033[0;0m"
                    echo -e "$STATUS"
                    echo -e "\\033[1;31mPas la dernière révision :\\033[0;0m"
                    echo -e "$MISSING"
                else
                    echo -e "\\033[1;32mA jour\\033[0;0m - \\033[1;31mChangements détectés :\\033[0;0m"
                    echo -e "$STATUS\n"
                fi
            else
                if [ $NEEDS_UPDATE -eq 1 ] ; then
                    echo -e "\\033[1;32mPas de changements détectés\\033[0;0m - \\033[1;31mPas la dernière révision :\\033[0;0m"
                    echo -e "$MISSING"
                else
                    echo -e "\\033[1;32mPas de changements détectés\\033[0;0m - \\033[1;32mA jour\\033[0;0m"
                fi
            fi
        fi
    fi
}

function scan_dir()
{
    DIR="$1"
    if [ -d "$DIR/.bzr" ] ; then
        if [ $QUIET -ne 1 ]; then
            echo -e "\\033[1;33mVérification du dépôt $DIR\\033[0;0m"
        fi
        check_depot $DIR
    else
        if [ $QUIET -ne 1 ]; then
            echo -e "\\033[1;33mVérification des dépôts dans $DIR\\033[0;0m"
        fi
        for i in $(ls $DIR); do
            if [ -d "$DIR/$i" ] ; then
                if [ -d "$DIR/$i/.bzr" ] ; then
                    if [ $QUIET -ne 1 ]; then
                        echo ""
                        echo -en "\\033[1;36m:: Vérification de $i ...\\033[0;0m"
                    fi
                    check_depot $DIR/$i
                elif [ $RECURSIVE -eq 1 ] ; then
                    # On ne parcours pas les éventuels répertoire CVS
                    if [ ! -d "$DIR/$i/CVS" ] ; then
                        scan_dir $DIR/$i
                    fi
                fi
            fi
        done
    fi
}

BZR_DIR=$(pwd)
BZR_OPT=""
CHECK_UPDATE=1
CHECK_COMMIT=1
QUIET=0
RECURSIVE=0

while [ $# -gt 0 ] ; do
    HAS_SPECIFIC_CHECK=0
    HAS_CHECK_UPDATE=0
    HAS_CHECK_COMMIT=0    
    case "$1" in
        --help|-h) shift ; usage ; exit 0 ; break ;;
        --short|-S) shift ; BZR_OPT="$BZR_OPT -S" ;;
        -u) shift ; HAS_SPECIFIC_CHECK=1 ; HAS_CHECK_UPDATE=1 ;;
        -c) shift ; HAS_SPECIFIC_CHECK=1 ; HAS_CHECK_COMMIT=1 ;;
        -q) shift ; QUIET=1 ;;
        -r) shift ; RECURSIVE=1 ;;
        *) BZR_DIR=$1 ; shift ; break ;;
        # plus de parametre -> sortie
        --) shift ; break ;;
    esac
    
    if [ $HAS_SPECIFIC_CHECK -eq 1 ]; then
        CHECK_UPDATE=0
        CHECK_COMMIT=0
        if [ $HAS_CHECK_UPDATE -eq 1 ]; then
            CHECK_UPDATE=1
        fi
        if [ $HAS_CHECK_COMMIT -eq 1 ]; then
            CHECK_COMMIT=1
        fi
    fi
done

if [ -d "$BZR_DIR" ] ; then
    scan_dir $BZR_DIR
else
    echo "$BZR_DIR n'est pas un répertoire existant"
fi
