Checks
=======

check-encoding.sh
-----------------

Nécessite iconv.
Sur une arborescence donnée (récursif), vérifie que les fichiers utilisent bien tous
l'encodage demandé. Un filtrage est possible sur une liste d'extension passée en 
paramètre.

check-syntax.sh
---------------

Permet de vérifier la syntaxe de différent language (un seul language par execution) 
sur les fichiers (en récursif) d'un répertoire donné. Peut filter par extension.

Languages gérés :
* PHP (nécessite d'avoir PHP CLI installé)
* Javascript (nécessite javascriptlint, http://javascriptlint.com/)
