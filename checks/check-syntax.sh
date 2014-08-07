#!/bin/sh
#
# Ce script permet de vérifier la syntaxe des fichiers pour certains langages, 
# en utilisant des outils de lint dédiés
#
# PHP : utilise l'option -l de l'interpréteur php local
# JAVASCRIPT : utilise javascriptlint (http://javascriptlint.com/). JSLint est 
# beaucoup trop strict et intégriste, et son fork JSHint pas encore utilisable 
# facilement en ligne de commande. De plus javascriptlint est en C complié, donc 
# beaucoup plus rapide (les autres sont en JS).
#
# Code de retour :
# 0 si tout va bien
# 1 si au moins un fichier a des erreurs ou warning de syntaxe (la liste des fichiers est écrit sur la sortie standard)
# 2 en cas d'autres erreurs (usage...)

PHP_VERSION_NEEDED="5.3"
PHP="/usr/bin/php"

SCRIPTDIR=`dirname $0`
SCRIPTDIR=$(cd $SCRIPTDIR ; pwd)

function usage()
{
	echo "Vérifie la syntaxe des fichiers de code pour le langage donné."
	echo
    echo "Usage : $0 php directory [extension extension extension ...]"
	echo "Où : "
	echo "  directory est le répertoire à analyser."
	echo "  extension sont les extensions des fichiers à tester. Si aucune extension n'est fournie, tous les fichiers du répertoire seront testés."
    echo "Exemple : $0 php . php"
}

function check_command()
{
	if type $1 &> /dev/null; then
		echo 1
	else
		echo 0
	fi
}

function php_syntax()
{
    # La version locale de PHP doit être supérieure ou égale à celle requise
    if [ ! $($PHP -r "echo version_compare(PHP_VERSION, '$PHP_VERSION_NEEDED');") -eq 1 ] ; then 
        echo "Version de PHP trop vieille"
        return; 
    fi

    HAS_ERROR=0
    for f in $FILES_LIST ; do
        ERRORS=$($PHP -l $f 2>&1 >/dev/null)
        if [ $? -gt 0 ] ; then
            HAS_ERROR=1
            echo -e "\nErreur de syntaxe dans le fichier $f : \n$ERRORS"
        fi
    done

    if [ $HAS_ERROR -eq 1 ] ; then
        exit 1
    fi
}

function js_syntax()
{
    JSL_CONF_FILE="sfc-jsl-conf.$$"
    cat << 'ENDOFCONF' > $JSL_CONF_FILE
### Warnings
# Enable or disable warnings based on requirements.
# Use "+WarningName" to display or "-WarningName" to suppress.
#
+no_return_value              # function {0} does not always return a value
+duplicate_formal             # duplicate formal argument {0}
+equal_as_assign              # test for equality (==) mistyped as assignment (=)?{0}
+var_hides_arg                # variable {0} hides argument
-redeclared_var               # redeclaration of {0} {1}
+anon_no_return_value         # anonymous function does not always return a value
-missing_semicolon            # missing semicolon
+meaningless_block            # meaningless block; curly braces have no impact
+comma_separated_stmts        # multiple statements separated by commas (use semicolons?)
+unreachable_code             # unreachable code
-missing_break                # missing break statement
-missing_break_for_last_case  # missing break statement for last case in switch
-comparison_type_conv         # comparisons against null, 0, true, false, or an empty string allowing implicit type conversion (use === or !==)
+inc_dec_within_stmt          # increment (++) and decrement (--) operators used as part of greater statement
+useless_void                 # use of the void type may be unnecessary (void is always undefined)
+multiple_plus_minus          # unknown order of operations for successive plus (e.g. x+++y) or minus (e.g. x---y) signs
+use_of_label                 # use of label
-block_without_braces         # block statement without curly braces
+leading_decimal_point        # leading decimal point may indicate a number or an object member
+trailing_decimal_point       # trailing decimal point may indicate a number or an object member
+octal_number                 # leading zeros make an octal number
-nested_comment               # nested comment
+misplaced_regex              # regular expressions should be preceded by a left parenthesis, assignment, colon, or comma
-ambiguous_newline            # unexpected end of line; it is ambiguous whether these lines are part of the same statement
-empty_statement              # empty statement or extra semicolon
-missing_option_explicit      # the "option explicit" control comment is missing
+partial_option_explicit      # the "option explicit" control comment, if used, must be in the first script tag
+dup_option_explicit          # duplicate "option explicit" control comment
+useless_assign               # useless assignment
+ambiguous_nested_stmt        # block statements containing block statements should use curly braces to resolve ambiguity
+ambiguous_else_stmt          # the else statement could be matched with one of multiple if statements (use curly braces to indicate intent)
-missing_default_case         # missing default case in switch statement
+duplicate_case_in_switch     # duplicate case in switch statements
+default_not_at_end           # the default case is not at the end of the switch statement
+legacy_cc_not_understood     # couldn't understand control comment using /*@keyword@*/ syntax
+jsl_cc_not_understood        # couldn't understand control comment using /*jsl:keyword*/ syntax
+useless_comparison           # useless comparison; comparing identical expressions
+with_statement               # with statement hides undeclared variables; use temporary variable instead
+trailing_comma_in_array      # extra comma is not recommended in array initializers
+assign_to_function_call      # assignment to a function call
-parseint_missing_radix       # parseInt missing radix parameter

### Output format
# Customize the format of the error message.
#    __FILE__ indicates current file path
#    __FILENAME__ indicates current file name
#    __LINE__ indicates current line
#    __ERROR__ indicates error message
+output-format __FILE__(__LINE__): __ERROR__

+context
+lambda_assign_requires_semicolon
+legacy_control_comments
-jscript_function_extensions
-always_use_option_explicit
+define window
+define document

ENDOFCONF

    # On complète le fichier de conf jsl avec la liste des fichiers js à analyser
    for f in $FILES_LIST ; do
        echo "+process "$( cd $(dirname $f); pwd)"/"$(basename $f) >> $JSL_CONF_FILE
    done

    # Lancement de jsl pour l'analyse syntaxique
    RESULTS=$($SCRIPTDIR/jsl -nologo -nofilelisting -conf $JSL_CONF_FILE)
    JSL_ERRORLEVEL=$?
    rm $JSL_CONF_FILE >/dev/null 2>&1

    if [ $JSL_ERRORLEVEL -gt 0 ] ; then
        echo -e "\n$RESULTS"
        exit 1
    fi
}

# Vérification du nombre de paramètres
if [ $# -lt 2 ]; then
	echo "*** paramètre manquant"
    usage
    exit 2
fi

LANGUAGE=$1
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
        FILES_LIST=$(find $DIRECTORY -type f | grep -E "$FILTER" | grep -v -E "$EXCLUDE_FILTER")
    else
        FILES_LIST=$(find $DIRECTORY -type f | grep -E "$FILTER")
    fi
else
    FILES_LIST=$(find $DIRECTORY -type f)
fi

case "$LANGUAGE" in
[pP][hH][pP])
    # On vérifie la présence de php, qui est nécessaire pour le fonctionnement du script
    if [ ! -x $PHP ] ; then
        echo "*** php est nécessaire pour ce script"
        exit 2
    fi
    php_syntax
    ;;  
[jJ][sS]|[jJ][aA][vV][aA][sS][cC][rR][iI][pP][tT])
    # On vérifie la présence de javascriptlint, qui est nécessaire pour le fonctionnement du script
    if [ ! -x "$SCRIPTDIR/jsl" ] ; then
        echo "*** $SCRIPTDIR/jsl est nécessaire pour ce script"
        exit 2
    fi
    js_syntax
    ;;  
*)
	echo "*** language '$LANGUAGE' inconnu"
    usage
    exit 2
    ;;
esac
