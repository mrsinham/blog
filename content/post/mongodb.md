+++
date = "2013-09-17T12:18:43+01:00"
tags = ["mongodb"]
title = "[FR] Un an avec MongoDb"
+++


#### Les conditions

##### L’environnement

Je travaille actuellement avec deux replicasets MongoDb, configurés comme 10gen l’a conseillé, c’est à dire trois serveurs de chaque côté qui donnent  ainsi un master et deux secondaires de chaque côté. C’est une configuration assez classique et sans une énorme charge compte tenu des machines musclées qui la composent. J’attaque des serveurs Mongos, toujours aucune surprise là encore qui connaissent la configuration et l’état du cluster. Cela veut donc dire que je suis dans des conditions des utilisateurs lambda de MongoDb dans le sens ou je n’ai pas des données réparties sur dix shards (ce qui signifierait tout de même 30 serveurs en configuration optimum) et que mes données ne se compte pas en milliards d’enregistrements.

##### Les gens

Aucun administrateur de base données dédié à MongoDb mais un DBA ayant suivi une formation MongoDb, des sysadmins qui connaissent bien leur métier et une équipe de développeurs qui ont comme tout le monde des livres ainsi que le célèbre RTFM pour se débrouiller. Pas la configuration optimale mais plutôt bien équipés.

#### Les erreurs

Nous rentrons dans le vif du sujet. Les erreurs sur cette technologie furent nombreuses et j’essaierai d’expliquer objectivement pourquoi elles ont eu lieu. Bien sûr, elle ne dépendent pas toute de la technologie et loin de là et partagerai mon expérience en prenant en compte le fait qu’elles viennent beaucoup de moi.

*Comment elle est trop hype cette Db.*

Qui n’a pas eu envie d’essayer cette dernière technologie si prometteuse dont tout le monde parle. Une base de données qui se sharde toute seule sur plusieurs serveurs sans point de défaillance ? Là encore l’engouement fut immense sur la technologie car de grands noms sont cités pour l’avoir utilisé. Evidemment la technologie doit se vendre et met en avant de belle pages en avant pour vanter que Foursquare et d’autres l’utilise. En plus, la technologie a atteint la version 2.0 et continue à être utilisée, l’esprit continue à être follement titillé. Bon bon, on a vu l’article qui a fait sensation sur pourquoi ne pas utiliser MongoDb mais cela semblait un peu provoc’ et certains arguments sont plus que limite. Allez, on se lance !

#### Une technologie totalement différente

Alors si MongoDb repose sur des principes qui font les bases de données d’aujourd’hui comme les index, le système de requête et de réponses, il y a de grosses différences avec les bases habituellement utilisées.

**Avec ton MongoDb, tu parles comme les jeunes en SMS.**

MongoDb a une syntaxe très différente du SQL. Alors vous me direz si on choisit cette technologie on est au courant qu’il va falloir apprendre de nouvelles choses, c’est notre métier donc bon, RTFM et tais toi.

Et bien non, car dans une entreprise moyenne il n’y aura pas que les développeurs qui devront exploiter votre base de données. Il y a des analystes, des testeurs qui vont s’assurer que les produits qu’ils testent réagissent bien par rapport aux données en base et il faut savoir que toute personne nouvellement impliquée sur le sujet soupirera à l’idée d’apprendre une nouvelle syntaxe : il y aura donc une perte de temps à l’initier, voir de motivation.

*« En SQL je l’aurai fait dix fois plus vite »*

Et bien ils n’ont pas tort, vu qu’ils ne connaissent pas bien celle de MongoDb et celle-ci est compliqué. Là ou le SQL est un langage basé sur des termes et une structure humaine, celle de MongoDb est basé sur les fonctions et donc est bien moins intuitive.

#### A grande scalabilité grandes restrictions.

Alors oui dès le départ on sait que cette technologie ne dispose pas de fonctionnalités comme les jointures. Et c’est un choix que l’on accepte car on sait qu’on peut différemment des façon de faire habituelle et que l’on a hâte de lui mettre des Tera dans la [gu.. ].  On peut consolider les données pour ne pas avoir à faire de jointure.

##### Cas du pour

On vous dira que de toute façon les jointures peuvent être coûteuses et que sur les données les plus utilisées il vaut mieux consolider. C’est souvent vrai si la donnée est intéressante et utilisée très fréquemment, il vaut mieux dédier un batch à la calculer.

##### Cas du contre

Oui pour vos projets vous aurez de toute façon à gérer vos données pertinentes et ne pas forcément faire des jointures en masse pour être performants. Mais tous les autres cas ?

* Lorsqu’on vous pose une question simple à laquelle une requête avec jointure aurait répondu facilement.
* Lorsqu’il faut faire un rapport sur telle et telle données et que ce rapport est à faire entre deux tâches métiers. Et bien ce rapport, vous allez devoir créer un batch qui se fait deux requêtes et les réunit pour créer les données que vous recherchez, et cela avec plus de risque de vous tromper.
* De plus, une base de données transactionnelle isolera un état des tables lors de la jointure tandis que votre batch pourra souffrir d’incohérences. Ce sont les principes d’Isolation et de Cohérence.
Vous ne pourrez faire qu’un seul champs réellement unique : la clé de sharding les serveurs n’ayant pas conscience des autres serveurs. Là ou d’autre base le font simplement avec un INDEX UNIQUE, un shard pourra déclarer un champs unique et pourtant un autre shard avoir des enregistrements avec la même donné.

#### Le piège du MongoId

Le MongoId est une sorte d’auto-increment hexadécimal qui est livré sur chaque enregistrement de la base. Il est composé de champs qui ont pour but de le rendre unique sur votre cluster que ce soit par rapport aux différents serveurs ou aux différentes collections.

95% des personnes qui veulent utiliser MongoDb le font pour le fait que cette base soit extensible horizontalement et fournir un identifiant unique pour chaque document est une chose très intelligente. Cela permet d’identifier facilement un document et travailler l’esprit en paix avec, mais son implémentation n’a pas été pensée pour la plupart des besoins et cela n’est pas très bien documenté.

Le but principal du MongoId a pour but de vous aider a sharder (c’est à dire diviser vos données) sur les différents serveurs pour que les requêtes travaillent sur des sous ensembles et puissent répondre beaucoup plus vite sur de très gros volumes. Pour cela vous identifiez dans la collection le champs qui servira de « clé de sharding ». En calculant un espèce de hash sur celui-ci, MongoDb va choisir de l’envoyer sur tel ou tel shard.

En utilisant le MongoId, cela se fait tout seul car il est garantit comme unique. Mais cela ne fonctionne que si vous ne supprimez pas des enregistrements et cela pour une raison enfouie dans la documentation. D’ici à ce que vous arriviez à ce point, vous aurez déjà shardé vos données selon les MongoId.

Le principe du sharding c’est que MongoDb empile les documents dans des boites appelées « chunks » et que ces chunks sont indivisibles, sauf manuellement. Ainsi, les enregistrement de A à F seront sur le 1 et de F à L sur le 2. Ces chunks sont définis ainsi, comme des espaces clairement définis par des barrière. Imaginez maintenant que tous les emplacements des chunks sont remplis mais que vous devez supprimer des documents sur des critères qui n’ont à voir avec des boites.

Ainsi, dans le premier chunk, B C E seront supprimés et dans la seconde seul le G le sera. Vous aurez donc deux chunks très déséquilibrés,  l’un en ayant perdu 3 et l’autre 1 seul. Vous me direz que MongoDb va alors combler les trous pour équilibrer et bien non: la clé de sharding en MongoId, l’algorithme de répartition est fortement lié à une date d’insertion dans la base et lorsque vous insérez rapidement, les données se trouvent naturellement dans le même chunk, souvent loin des chunks déjà existant.

Donc au lieu de combler les trous, il crééra le chunk M à P et mettra ses données dedans, vous laissant au fur et à mesure avec des boites remplies de trou et on arrive au problème final :

*MongoDb ne répartit et déplace ses données qu’en bougeant les chunks, pas les documents indépendamment.*

Résultat, vous aurez le meme nombre de chunk de chaque côté, mais en définitive un shard peut etre largement déséquilibré en terme de document par rapport à l’autre. Plutôt tordu non ?

Afin de résoudre ce problème il faut prendre un algorithme de répartition linéaire comme un CRC64 de champs obligatoires du documents et la les documents seront repartis aléatoirement sur chaque shard et donc vous n’aurez pas de déséquilibre.

Pour une « Core feature » d’un moteur de base de donnée, je trouve que le MongoId aurait du être davantage travaillé pour être moins dangereux dans ce genre de cas qui représente beaucoup de monde.

*« Le MongoId est parfait pour les cas où on ne supprime jamais, c’est à dire 5% des cas. »*

#### « Je ne vous entends qu’à moitié ! »

Pour comprendre ce problème, il faut savoir que lorsqu’on se connecte à un environnement « shardé » on le fait via un démon appelé MongoS. Ce démon lit les informations des serveurs de configuration et se connecte aux serveurs qu’il estime comme pertinents pour répondre aux requêtes. Contrairement aux base de données comme Cassandra ou Riak, il y a donc un point de défaillance en la présence de ce démon là ou vous pouvez attaquer les données de n’importe quel point sur les autres. Bien sûr, vous pouvez en lancer plusieurs sur plusieurs machines, mais c’est autant de point d’accès à configurer et la connexion est manuelle (oblige donc à utiliser un démon comme ha-proxy).

Or il arrive que le démon MongoS ne voit qu’une partie des shards (dans le cas présent, 1 sur 2) à cause d’un problème réseau ou autre. Même si le démon l’indique dans son exécution, les drivers ignorent complètement qu’ils travaillent sur la moitié des serveurs car le MongoS leur cache la complexité. Ainsi si vous dumpez vos données vous n’en aurez que la moitié ! Vous croirez que votre base a juste fondu et si vous avez des relations entre vos collections certaines ne mèneront nulle part.

Certes cette base n’est pas ACID mais on en demande un minimum et ce genre de situation est grave.

#### Les tables c’est has been, moi je suis free, schema-less.

Insérer un document qui n’a rien à voir avec le précédent est bien sur étrange mais on s’y fait. Evidemment, on essaie de faire des structures qui ont un sens mais une étrange sensation de liberté vous pousse à rajouter des champs à tout va. Cela a son utilité lorsque vous indexerez des données très hétéroclites mais dans les autres cas les tables et leurs colonnes figées vous manqueront.

Pourquoi ?

Imaginez que vous avez un champs appelé « facturation_status » rempli sur les trois quarts des documents et que vous voulez le renommer en « status ». Vous ne pourrez pas faire un alter table, vous allez devoir recopier via un requête toutes les valeurs de « facturation_status » dans le nouveau champs et croyez moi que cette requête ne sera pas simple à exécuter. Certes le alter table est coûteux mais l’instant d’avant et d’après sont cohérents. Si votre requête échoue en plein milieu pour des problèmes de lock, vous aurez un cas que vous ne voudrez pas affronter sur une base de production.

Comme vos champs ne seront pas toujours présent, cela vous obligera à tester dans chaque document lu si le champs existe ou non: une perte de temps.

De plus, vous ne pourrez pas affirmer que les champs de votre base seront tous des booléens ou des entiers. Imaginez les dommages sur des langages typés fortement. Bref, sans limite ou bordure cela peut devenir très vite le chaos.

#### Des erreurs de jeunesse

Cette technologie a de nombreuses erreurs/bugs de jeunesse comme des doublons dans les export, des démons qui parfois segfault ou se comportent bizarrement. De nombreux tickets de retours sont ouverts et il faudra un moment avant que la technologie ne se stabilise.

Combien de fois j’ai reçu une erreur MongoDb d’un développeur qui travaillait sur la même machine que fois alors que j’étais sur un autre code et que mon erreur réelle était bien différente. Les drivers sont encore très jeunes aussi.

Avoir choisi un démon comme point d’entrée unique au serveur est aussi une erreur car la scalabilité se fait au travers de réseau qui peuvent à tout moment lâcher. Une plus grande tolérance à la panne est requise pour se vanter d’être extensible horizontalement.

#### En conclusion

MongoDb est une technologie très intéressante sur le papier mais elle souffre d’un manque de possibilités et d’une complexité qui n’a pas lieu d’être. Certes ce genre de technologie ne s’apprivoise pas comme une base MySQL sur un serveur dédié personnel mais tout de même : on rencontre de nombreux problème qui ne sont absolument pas liés à vos demandes métiers et le temps perdu à les résoudre sera autant de choses que vous devrez justifier. Il y de bonne features dont je n’ai pas parlé comme les indexes géographique, le fait d’avoir un indexe multivalué qui permet de chercher un champs dans un tableau indexé numériquement et d’autre très sympathique mais le but de cet article est de remonter une vision plus pragmatique plutôt que d’essayer de faire contrepoids avec quelques points positifs qui ne vous feront pas gagner autant de temps que vous en aurez perdu.