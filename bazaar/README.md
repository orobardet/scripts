Bazaar
=======

check-sub-bzr.sh, clean-sub-bzr.sh, update-sub-bzr.sh
-----------------------------------------------------

Tout ces scripts travail sur le répertoire courant ou celui en paramètre.
Si le répertoire est un dépôt Bazaar, l'action est effectuée directement dessus.
Sinon, scan tous les sous-repertoires (directs, pas de récursion), et pour tout 
ceux qui sont des dépôts Bazaar, effectue l'action.

* check-sub-bzr.sh : Vérifie que la branche local est à jour par rapport à celle 
bindée (est-ce qu'il manque des révisions et nécessite un update ?) ; Vérifie qu'il n'y 
a pas des changements non commités.
* update-sub-bzr.sh : Réalise un bzr update.
* clean-sub-bzr.sh : Nettoie le dépôt en supprimant les fichiers correspondant au 
.bzrignore (bzr clean-tree --ignored)

change-bzr-branch.sh
--------------------

Si le répertoire courant correspond à une dépôt, le script va changer sa branche courante 
par celle passée en paramètre, avec vérification s'il n'y a rien à commiter.

* Vérifie que la branche demandée existe
* Vérifie si y a des changements locaux non commités, et si oui demande confirmation
à l'utilisateur de continuer (car tout sera perdu
* Fait un bzr reverse pour nettoyer tous les changements en attente (et éviter de polluer 
la nouelle branche car bzr switch conserve les changement)
* Fait un bzr switch sur la nouvelle branche demandée (doit exister)
* Faut un bzr update pour finir pour mettre à jour la nouvelle branche
