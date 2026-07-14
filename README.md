# FS25 DispoList

**🇩🇪 [Deutsch](#deutsch)** | **🇬🇧 [English](#english)** | **🇫🇷 [Français](#français)** | **🇮🇹 [Italiano](#italiano)** | **🇵🇹 [Português](#português)** | **🇪🇸 [Español](#español)**

---

## 🇩🇪 Deutsch <a name="deutsch"></a>

### ⚠️ Bevor du dich wunderst (Stolpersteine)

- **„Der Gesamtwert bewegt sich beim Verkaufen kaum / wirkt viel zu hoch"** → DispoList zählt ab Werk **alle** Lagertypen mit — auch Tierhaltung und Fabrik-Ausgänge auf der **ganzen Karte**. Verkaufst du lokal ein paar Paletten, fällt das gegen den globalen Berg kaum auf. **Tipp:** In den Einstellungen nur die Lagertypen aktivieren, die du wirklich brauchst (z. B. nur Zentrallager + Silos).
- **„Die Werte aktualisieren sich nicht"** → Sortierst du nach **Wert**, pausiert der Auto-Refresh absichtlich (sonst springt die Liste ständig). Es zeigt „Pausiert". Zurück auf **A–Z**, und alles läuft wieder.
- **„Alles zeigt 0 / nichts ist sichtbar"** → Meist sind die falschen Lagertypen aktiv. Das HUD sagt dir das inzwischen selbst („Pruefe die aktiven Lagertypen").
- **„Bester Monat zeigt nichts"** → Angezeigt wird nur, was **gerade jetzt** seinen besten Verkaufsmonat hat. Manche Monate haben keinen Peak — dann bleibt's leer. Kein Fehler, nur der Kalender. 😉
- **„Frei ist kleiner als erwartet, obwohl ich genug Lager hab"** → Prüf, ob du eine Baustelle mit [EverythingConstructable](https://farming-simulator.com) offen hast — DispoList zieht deren Materialbedarf automatisch von der freien Menge ab (siehe Feature-Liste unten), erkennbar an der zweiten Zeile über der Warenliste.

---

### Was ist DispoList?

DispoList ist ein HUD-Mod für Farming Simulator 25 der dir einen schnellen Überblick über deine Lagerbestände und die besten Verkaufspreise gibt — direkt im Spiel, ohne Menüs.

Besonderheit: Die **freien Waren** werden automatisch errechnet — also was deine Produktionen gerade erzeugen und nicht selbst weiterverarbeiten. Der Produktionspuffer (wie viel im Lager bleibt bevor es als "frei" gilt) ist einstellbar. So siehst du auf einen Blick was du verkaufen oder weiterliefern kannst.

### Features

- 🔄 **Freie Waren** — Automatische Berechnung was aus Produktionen zum Verkauf/Transport verfügbar ist
- 📦 **Lagerbestand** — Aktueller Bestand und freie Kapazität pro Ware
- 🔎 **Lageransicht** — Klick auf eine Ware zeigt, in welchem Lager wie viel liegt (Zentrallager, Silos, Tierhaltung, Fabrik-Ausgänge u.v.m.)
- 🧮 **Lagertypen wählbar** — selbst bestimmen was mitgezählt wird (Zentrallager, Silos, Silo-Extensions, Tierhaltung, Misthaufen, Fahrsilo, Objektlager, Fabrik-Ausgänge)
- 💰 **Bestpreise** — Bester und maximaler Verkaufspreis pro Ware und Monat
- 🔵 **Blaue Hervorhebung** — Waren, deren bester Verkaufsmonat gerade jetzt ist, werden **blau** markiert — dann lohnt sich der Verkauf am meisten
- 🏗️ **Baustellen-Bedarf** — Optional, mit [EverythingConstructable](https://farming-simulator.com): reserviert automatisch das noch benötigte Material offener Bauprojekte von der freien Menge (zusätzlich zum Fabrik-Puffer), damit du nicht versehentlich Material wegverkaufst, das du selbst für die Baustelle brauchst. Ein-/ausschaltbar direkt per Klick auf die Frei-Erklärungszeile im Haupt-HUD; nur sichtbar, wenn der Mod installiert ist
- 🏭 **Gesamtwert** — Wert aller freier Waren pro Station
- 🗂️ **Bereiche** — Waren nach eigenen Kategorien gruppieren (z.B. Getreide, Flüssig, Kühlung)
- ✏️ **Bereiche verwalten** — eigene Bereiche anlegen, umbenennen und löschen
- 🏪 **Stationen** — Filteransicht pro Verkaufsstation
- ⭐ **CW only** — Nur Zentrallager-Bereiche anzeigen (ideal für NF Marsch)
- 🔍 **Suche** — Schnellsuche nach Waren oder Stationen
- 🎛️ **Presets** — Vorgefertigte Bereiche-Konfigurationen:
  - *Selbst*: deine eigene Einteilung bleibt erhalten
  - *Zentrallager*: optimiert für Karten mit Zentrallager (z.B. NF Marsch)
  - *Giants*: Standard-Kategorien aus dem Spiel
- ⏱️ **Refresh-Intervall** — Einstellbar (5s / 15s / 30s / 60s / 120s / manuell) für optimale Performance
- 🌗 **Kontrast/Transparenz** — Box-Hintergrund in 3 Stufen (hell / dunkel / transparent)
- 📜 **Mausrad-Scrollen** — in beiden Listen bequem per Mausrad blättern
- 🌍 **Mehrsprachig** — DE, EN, FR, IT, PT, ES
- 🖱️ **Maussteuerung** — Vollständig per Maus bedienbar inkl. sichtbarem Mauscursor im HUD (F9 / F12, je nach HL HUD System Einstellung)

### Voraussetzungen

- Farming Simulator 25
- Optional: [EverythingConstructable](https://farming-simulator.com) für die Baustellen-Bedarf-Funktion (Mod läuft auch ohne, die Funktion bleibt dann einfach ausgeblendet)

### Installation

1. ZIP-Datei herunterladen
2. In den Mods-Ordner entpacken: `Dokumente/My Games/FarmingSimulator2025/mods/`
3. Mod im Spiel aktivieren
4. **Shift+C** zum Ein-/Ausblenden der DispoList (in den Einstellungen anpassbar)
5. **F9 / F12** für Maussteuerung (je nach HL HUD System Einstellung)

### Steuerung

| Aktion | Taste / Maus |
|---|---|
| DispoList ein/aus | `Shift + C` (anpassbar) |
| Maussteuerung | `F9 / F12` (HL HUD System) |
| Einstellungsmenü öffnen | Klick auf das Einstellungen-Icon in der Icon-Leiste |
| Spalten ein/aus | Einstellungsmenü → „Spalten anzeigen" |
| Lageransicht (Drill-Down) | Klick auf die Warenzeile |
| Bereich zuordnen | Filter-HUD → Ware anklicken, dann Zielbereich anklicken |
| Bereich erstellen | „+ Neuer Bereich" — oberste Zeile der Bereiche-Liste |
| Bereich umbenennen/löschen | Rechtsklick auf einen Bereich → Kontextmenü |
| Sortierung Wert ↔ A–Z | Klick auf das Sortier-Icon (Wert-Sortierung pausiert den Refresh) |
| Kontrast/Transparenz | Klick auf das Kontrast-Icon in der Icon-Leiste |
| Listen scrollen | Mausrad |
| CW only Toggle | Stern-Icon ⭐ in der Icon-Leiste |
| Baustellen-Bedarf ein/aus | Klick auf die Frei-Erklärungszeile im Haupt-HUD (nur sichtbar mit EverythingConstructable) |
| Refresh-Intervall | Einstellbar im Einstellungsmenü |

### Einstellungsmenü

Ein Klick auf das **Einstellungen-Icon** in der Icon-Leiste öffnet das Einstellungsmenü — alle Optionen an einem Ort:

- **Spalten anzeigen** — jede Spalte einzeln ein-/ausblenden: Bestand, Frei, Preis/1000l, Max/1000l, Wert, Frei Wert, Max €, Frei Max, Bester Monat
- **Fabrik-Puffer** — über `[−]` / `[+]` einstellen, wie viele Stunden Vorrat im Lager bleiben, bevor Ware als „frei" gilt (Formel: Bestand − Bedarf/h × Puffer = freie Menge)
- **Lagertypen** — festlegen, was mitgezählt wird (Zentrallager, Silos, Silo-Extensions, Tierhaltung, Misthaufen, Fahrsilo, Objektlager, Fabrik-Ausgänge); angezeigt werden nur die Typen, die es auf deiner Karte wirklich gibt
- **Bereiche-Preset** — „Selbst einrichten" (nichts ändern), „Zentrallager-Preset laden" oder „Giants-Standard laden"

> 💡 **Gut zu wissen:** Sobald du die Liste nach **Wert** sortierst (Klick auf das Sortier-Icon), pausiert der automatische Refresh und zeigt „Pausiert" an. Das ist Absicht — sonst würden die Zeilen bei jeder Aktualisierung ihre Plätze tauschen und die Liste würde dir wegspringen. Zurück auf **A–Z**, und der Refresh läuft wieder ganz normal.

> 🏗️ **Baustellen-Bedarf:** Ist [EverythingConstructable](https://farming-simulator.com) installiert, erscheint über der Frei-Erklärung eine zusätzliche Zeile „Fabrikpuffer / Baustelle". Der Erklärsatz darunter zeigt automatisch an, ob Baustellen-Bedarf gerade mit abgezogen wird — ein Klick darauf schaltet es um.

### Multiplayer

Grundsätzlich MP-fähig — jeder Spieler benötigt den Mod. **Nicht offiziell getestet**, Nutzung auf eigene Gefahr.

### Credits

- **HappyLooser** — HL HUD System Framework (mit freundlicher Genehmigung zur Einbettung — vielen Dank für die Freigabe!)
- **FedAction** — NF Marsch Karte & Inspiration für den Zentrallager-Filter
- **LazyChilla** — Mod-Entwicklung

---

## 🇬🇧 English <a name="english"></a>

### ⚠️ Before you wonder (common pitfalls)

- **"The total value barely moves when I sell / seems way too high"** → By default DispoList counts **all** storage types — including animal pens and factory outputs across the **whole map**. Selling a few local pallets barely dents that global pile. **Tip:** in the settings, only enable the storage types you actually need (e.g. just central warehouse + silos).
- **"The values don't update"** → When you sort by **value**, the auto-refresh pauses on purpose (otherwise the list keeps jumping). It shows "Paused". Switch back to **A–Z** and it runs again.
- **"Everything shows 0 / nothing is visible"** → Usually the wrong storage types are active. The HUD now tells you itself ("Check your active storage types").
- **"Best month shows nothing"** → Only goods whose **best selling month is right now** are shown. Some months have no peak — then it stays empty. Not a bug, just the calendar. 😉
- **"Free is lower than expected even though I have plenty of storage"** → Check whether you have an open construction site with [EverythingConstructable](https://farming-simulator.com) — DispoList automatically deducts its material demand from the free amount (see feature list below), visible as a second line above the goods list.

---

### What is DispoList?

DispoList is a HUD mod for Farming Simulator 25 that gives you a quick overview of your storage levels and the best selling prices — directly in-game, without any menus.

Special feature: **Free goods** are calculated automatically — meaning what your productions are currently generating and not processing further. The production buffer (how much stays in storage before it counts as "free") is configurable. So you can see at a glance what you can sell or deliver.

### Features

- 🔄 **Free goods** — Automatic calculation of what is available from productions for sale/transport
- 📦 **Stock** — Current stock and free capacity per product
- 🔎 **Storage view** — Click a product to see which storage holds how much (central warehouse, silos, animal pens, factory outputs and more)
- 🧮 **Selectable storage types** — Decide yourself what gets counted (central warehouse, silos, silo extensions, animal pens, manure heaps, bunker silos, object storage, factory outputs)
- 💰 **Best prices** — Best and maximum selling price per product and month
- 🔵 **Blue highlight** — Goods whose best selling month is right now are marked **blue** — that's when selling pays off most
- 🏗️ **Construction site demand** — Optional, with [EverythingConstructable](https://farming-simulator.com): automatically reserves material still needed for open construction projects from the free amount (on top of the factory buffer), so you don't accidentally sell off material you need for your own site. Toggle directly by clicking the free-amount explanation line in the main HUD; only visible if the mod is installed
- 🏭 **Total value** — Value of all free goods per station
- 🗂️ **Zones** — Group products into custom categories (e.g. Grain, Liquid, Cooling)
- ✏️ **Manage zones** — Create, rename and delete your own zones
- 🏪 **Stations** — Filter view per selling station
- ⭐ **CW only** — Show central warehouse zones only (ideal for NF Marsch)
- 🔍 **Search** — Quick search for products or stations
- 🎛️ **Presets** — Preset zone configurations:
  - *Custom*: keep your own zone setup
  - *Central WH*: optimised for maps with central warehouse (e.g. NF Marsch)
  - *Giants*: default categories from the base game
- ⏱️ **Refresh interval** — Configurable (5s / 15s / 30s / 60s / 120s / manual) for optimal performance
- 🌗 **Contrast/Transparency** — Box background in 3 levels (bright / dark / transparent)
- 📜 **Mouse wheel scrolling** — Scroll both lists conveniently with the mouse wheel
- 🌍 **Multilingual** — DE, EN, FR, IT, PT, ES
- 🖱️ **Mouse control** — Fully operable via mouse incl. visible cursor in the HUD (F9 / F12, depends on HL HUD System setting)

### Requirements

- Farming Simulator 25
- Optional: [EverythingConstructable](https://farming-simulator.com) for the construction site demand feature (the mod works fine without it, the feature simply stays hidden)

### Installation

1. Download the ZIP file
2. Extract to your mods folder: `Documents/My Games/FarmingSimulator2025/mods/`
3. Activate the mod in-game
4. **Shift+C** to toggle the DispoList (configurable in settings)
5. **F9 / F12** for mouse control (depends on HL HUD System setting)

### Controls

| Action | Key / Mouse |
|---|---|
| Toggle DispoList | `Shift + C` (configurable) |
| Mouse control | `F9 / F12` (HL HUD System) |
| Open settings menu | Click the settings icon in the icon bar |
| Toggle columns | Settings menu → "Show columns" |
| Storage view (drill-down) | Click a product row |
| Assign zone | Filter HUD → click product, then click target zone |
| Create zone | "+ Neuer Bereich" button — top row of the zone list |
| Rename/delete zone | Right-click a zone → context menu |
| Sort by value ↔ A–Z | Click the sort icon (value sorting pauses the refresh) |
| Contrast/transparency | Click the contrast icon in the icon bar |
| Scroll lists | Mouse wheel |
| CW only toggle | Star icon ⭐ in icon bar |
| Toggle construction site demand | Click the free-amount explanation line in the main HUD (only visible with EverythingConstructable) |
| Refresh interval | Configurable in the settings menu |

### Settings menu

Clicking the **settings icon** in the icon bar opens the settings menu — every option in one place:

- **Show columns** — toggle each column individually: Stock, Free, Price/1000l, Max/1000l, Value, Free Value, Max €, Free Max, Best Month
- **Production buffer** — use `[−]` / `[+]` to set how many hours of supply stay in storage before goods count as "free" (formula: Stock − Demand/h × Buffer = free amount)
- **Storage types** — decide what gets counted (central warehouse, silos, silo extensions, animal pens, manure heaps, bunker silos, object storage, factory outputs); only the types that actually exist on your map are shown
- **Zone preset** — "Set up yourself" (no change), "Load central warehouse preset" or "Load Giants default"

> 💡 **Good to know:** As soon as you sort the list by **value** (click the sort icon), the automatic refresh pauses and shows "Paused". That's intentional — otherwise the rows would swap places on every update and the list would jump away from you. Switch back to **A–Z** and the refresh runs normally again.

> 🏗️ **Construction site demand:** If [EverythingConstructable](https://farming-simulator.com) is installed, an extra line "Factory buffer / construction site" appears above the free-amount explanation. The sentence below it automatically shows whether construction site demand is currently being deducted — click it to toggle.

### Multiplayer

Generally MP-capable — each player needs the mod. **Not officially tested**, use at your own risk.

### Credits

- **HappyLooser** — HL HUD System Framework (kindly granted permission to embed — many thanks for the go-ahead!)
- **FedAction** — NF Marsch map & inspiration for the central warehouse filter
- **LazyChilla** — Mod development

---

## 🇫🇷 Français <a name="français"></a>

### ⚠️ Avant de vous étonner (pièges fréquents)

- **« La valeur totale bouge à peine quand je vends / semble bien trop élevée »** → Par défaut, DispoList compte **tous** les types de stockage — y compris élevages et sorties d'usine sur **toute la carte**. Vendre quelques palettes locales ne change presque rien face à ce tas global. **Astuce :** dans les paramètres, n'activez que les types de stockage dont vous avez besoin (p. ex. entrepôt central + silos).
- **« Les valeurs ne se mettent pas à jour »** → Quand vous triez par **valeur**, le rafraîchissement auto se met en pause exprès (sinon la liste saute sans arrêt). Il affiche « En pause ». Revenez sur **A–Z** et ça repart.
- **« Tout affiche 0 / rien n'est visible »** → En général, les mauvais types de stockage sont actifs. Le HUD vous le dit maintenant lui-même (« Vérifiez les types de stockage actifs »).
- **« Meilleur mois n'affiche rien »** → Seuls les produits dont le **meilleur mois de vente est en cours** sont affichés. Certains mois n'ont pas de pic — alors ça reste vide. Pas un bug, juste le calendrier. 😉
- **« Libre est plus bas que prévu alors que j'ai assez de stock »** → Vérifiez si vous avez un chantier ouvert avec [EverythingConstructable](https://farming-simulator.com) — DispoList déduit automatiquement son besoin en matériel de la quantité libre (voir liste des fonctionnalités ci-dessous), visible comme une deuxième ligne au-dessus de la liste des produits.

---

### Qu'est-ce que DispoList?

DispoList est un mod HUD pour Farming Simulator 25 qui vous donne un aperçu rapide de vos stocks et des meilleurs prix de vente — directement dans le jeu, sans menus.

Particularité: Les **produits libres** sont calculés automatiquement — ce que vos productions génèrent et ne traitent pas elles-mêmes. Le tampon de production est configurable. Vous voyez d'un coup d'œil ce que vous pouvez vendre ou livrer.

### Fonctionnalités

- 🔄 **Produits libres** — Calcul automatique des produits disponibles à la vente/transport
- 📦 **Stock** — Stock actuel et capacité libre par produit
- 🔎 **Vue de stockage** — Cliquez sur un produit pour voir quel stock en contient combien (entrepôt central, silos, élevages, sorties d'usine, etc.)
- 🧮 **Types de stockage sélectionnables** — Décidez vous-même ce qui est compté (entrepôt central, silos, extensions de silo, élevages, tas de fumier, silos-couloirs, stockage d'objets, sorties d'usine)
- 💰 **Meilleurs prix** — Meilleur et maximum prix de vente par produit et par mois
- 🔵 **Surlignage bleu** — Les produits dont le meilleur mois de vente est en cours sont marqués en **bleu** — c'est le moment le plus rentable pour vendre
- 🏗️ **Besoin de chantier** — Optionnel, avec [EverythingConstructable](https://farming-simulator.com) : réserve automatiquement le matériel encore nécessaire aux chantiers ouverts sur la quantité libre (en plus du tampon d'usine), pour éviter de vendre par erreur du matériel dont vous avez besoin pour votre chantier. Activable directement en cliquant sur la ligne d'explication de la quantité libre dans le HUD principal ; visible uniquement si le mod est installé
- 🏭 **Valeur totale** — Valeur de tous les produits libres par station
- 🗂️ **Zones** — Regroupez les produits par catégories (ex. Céréales, Liquide, Réfrigération)
- ✏️ **Gérer les zones** — Créez, renommez et supprimez vos propres zones
- 🏪 **Stations** — Vue filtrée par station de vente
- ⭐ **CW only** — Afficher uniquement les zones d'entrepôt central (idéal pour NF Marsch)
- 🔍 **Recherche** — Recherche rapide de produits ou stations
- 🎛️ **Préréglages** — Configurations de zones prédéfinies (Personnalisé / Entrepôt central / Giants standard)
- ⏱️ **Intervalle de rafraîchissement** — Configurable (5s / 15s / 30s / 60s / 120s / manuel)
- 🌗 **Contraste/Transparence** — Fond de la boîte en 3 niveaux (clair / sombre / transparent)
- 📜 **Défilement à la molette** — Faites défiler les deux listes à la molette de la souris
- 🌍 **Multilingue** — DE, EN, FR, IT, PT, ES

### Prérequis

- Farming Simulator 25
- Optionnel : [EverythingConstructable](https://farming-simulator.com) pour la fonctionnalité de besoin de chantier (le mod fonctionne aussi sans, la fonctionnalité reste simplement masquée)

### Installation

1. Téléchargez le fichier ZIP
2. Extrayez-le dans votre dossier mods : `Documents/My Games/FarmingSimulator2025/mods/`
3. Activez le mod dans le jeu
4. **Shift+C** pour afficher/masquer la DispoList (configurable dans les paramètres)
5. **F9 / F12** pour le contrôle à la souris (selon le réglage du HL HUD System)

### Contrôles

| Action | Touche / Souris |
|---|---|
| Afficher/masquer la DispoList | `Shift + C` (configurable) |
| Contrôle à la souris | `F9 / F12` (HL HUD System) |
| Ouvrir le menu des paramètres | Clic sur l'icône des paramètres dans la barre d'icônes |
| Afficher/masquer les colonnes | Menu des paramètres → « Afficher les colonnes » |
| Vue de stockage (détail) | Clic sur la ligne d'un produit |
| Attribuer une zone | HUD de filtre → clic sur le produit, puis clic sur la zone cible |
| Créer une zone | Bouton « + Neuer Bereich » — première ligne de la liste des zones |
| Renommer/supprimer une zone | Clic droit sur une zone → menu contextuel |
| Tri par valeur ↔ A–Z | Clic sur l'icône de tri (le tri par valeur met en pause le rafraîchissement) |
| Contraste/transparence | Clic sur l'icône de contraste dans la barre d'icônes |
| Faire défiler les listes | Molette de la souris |
| Bascule CW only | Icône étoile ⭐ dans la barre d'icônes |
| Activer/désactiver le besoin de chantier | Clic sur la ligne d'explication de la quantité libre dans le HUD principal (visible uniquement avec EverythingConstructable) |
| Intervalle de rafraîchissement | Configurable dans le menu des paramètres |

### Menu des paramètres

Un clic sur l'**icône des paramètres** dans la barre d'icônes ouvre le menu des paramètres — toutes les options au même endroit :

- **Afficher les colonnes** — activez/désactivez chaque colonne individuellement : Stock, Libre, Prix/1000l, Max/1000l, Valeur, Valeur libre, Max €, Max libre, Meilleur mois
- **Tampon de production** — réglez avec `[−]` / `[+]` combien d'heures de réserve restent en stock avant qu'un produit ne soit considéré comme « libre » (formule : Stock − Besoin/h × Tampon = quantité libre)
- **Types de stockage** — décidez ce qui est compté (entrepôt central, silos, extensions de silo, élevages, tas de fumier, silos-couloirs, stockage d'objets, sorties d'usine) ; seuls les types réellement présents sur votre carte sont affichés
- **Préréglage de zones** — « Configurer soi-même » (aucun changement), « Charger le préréglage entrepôt central » ou « Charger le standard Giants »

> 💡 **Bon à savoir :** Dès que vous triez la liste par **valeur** (clic sur l'icône de tri), le rafraîchissement automatique se met en pause et affiche « En pause ». C'est voulu — sinon les lignes changeraient de place à chaque mise à jour et la liste vous « échapperait ». Revenez sur **A–Z** et le rafraîchissement reprend normalement.

> 🏗️ **Besoin de chantier :** Si [EverythingConstructable](https://farming-simulator.com) est installé, une ligne supplémentaire « Tampon d'usine / chantier » apparaît au-dessus de l'explication de la quantité libre. La phrase en dessous indique automatiquement si le besoin de chantier est actuellement déduit — cliquez dessus pour basculer.

### Multijoueur

Compatible multijoueur en principe — chaque joueur a besoin du mod. **Non testé officiellement**, utilisation à vos propres risques.

### Crédits

- **HappyLooser** — Framework HL HUD System (aimablement autorisé à l'intégration — un grand merci pour l'accord!)
- **FedAction** — Carte NF Marsch & inspiration pour le filtre entrepôt central
- **LazyChilla** — Développement du mod

---

## 🇮🇹 Italiano <a name="italiano"></a>

### ⚠️ Prima di stupirti (errori comuni)

- **« Il valore totale si muove appena quando vendo / sembra troppo alto »** → Di default DispoList conta **tutti** i tipi di deposito — inclusi allevamenti e uscite di produzione su **tutta la mappa**. Vendere qualche pallet in loco incide poco su quel mucchio globale. **Consiglio:** nelle impostazioni attiva solo i tipi di deposito che ti servono davvero (es. solo magazzino centrale + sili).
- **« I valori non si aggiornano »** → Quando ordini per **valore**, l'aggiornamento automatico va in pausa di proposito (altrimenti la lista salta di continuo). Mostra « In pausa ». Torna su **A–Z** e riparte.
- **« Tutto mostra 0 / non si vede niente »** → Di solito sono attivi i tipi di deposito sbagliati. Ora l'HUD te lo dice da solo (« Controlla i tipi di deposito attivi »).
- **« Miglior mese non mostra niente »** → Vengono mostrate solo le merci il cui **miglior mese di vendita è proprio ora**. Alcuni mesi non hanno un picco — allora resta vuoto. Non è un bug, è solo il calendario. 😉
- **« Libero è più basso del previsto anche se ho abbastanza scorte »** → Controlla se hai un cantiere aperto con [EverythingConstructable](https://farming-simulator.com) — DispoList detrae automaticamente il suo fabbisogno di materiale dalla quantità libera (vedi elenco funzionalità sotto), visibile come seconda riga sopra l'elenco delle merci.

---

### Cos'è DispoList?

DispoList è un mod HUD per Farming Simulator 25 che ti offre una panoramica rapida delle scorte e dei migliori prezzi di vendita — direttamente nel gioco, senza menu.

Caratteristica speciale: Le **merci libere** vengono calcolate automaticamente — ciò che le tue produzioni generano e non elaborano ulteriormente. Il buffer di produzione è configurabile. Vedi a colpo d'occhio cosa puoi vendere o consegnare.

### Funzionalità

- 🔄 **Merci libere** — Calcolo automatico di ciò che è disponibile dalle produzioni per vendita/trasporto
- 📦 **Scorte** — Scorte attuali e capacità libera per prodotto
- 🔎 **Vista magazzino** — Clicca su un prodotto per vedere in quale deposito e quanto è stoccato (magazzino centrale, sili, allevamenti, uscite di produzione, ecc.)
- 🧮 **Tipi di deposito selezionabili** — Decidi tu cosa viene conteggiato (magazzino centrale, sili, estensioni sili, allevamenti, cumuli di letame, trincee, deposito oggetti, uscite di produzione)
- 💰 **Prezzi migliori** — Prezzo di vendita migliore e massimo per prodotto e mese
- 🔵 **Evidenziazione blu** — Le merci il cui miglior mese di vendita è proprio ora sono in **blu** — è il momento più redditizio per vendere
- 🏗️ **Fabbisogno cantiere** — Opzionale, con [EverythingConstructable](https://farming-simulator.com): riserva automaticamente il materiale ancora necessario per i cantieri aperti dalla quantità libera (in aggiunta al buffer di fabbrica), per evitare di vendere per errore materiale che ti serve per il tuo cantiere. Attivabile direttamente cliccando sulla riga di spiegazione della quantità libera nell'HUD principale; visibile solo se il mod è installato
- 🏭 **Valore totale** — Valore di tutte le merci libere per stazione
- 🗂️ **Zone** — Raggruppa i prodotti in categorie personalizzate
- ✏️ **Gestione zone** — Crea, rinomina ed elimina le tue zone
- 🏪 **Stazioni** — Vista filtrata per stazione di vendita
- ⭐ **CW only** — Mostra solo le zone del magazzino centrale (ideale per NF Marsch)
- 🔍 **Ricerca** — Ricerca rapida di prodotti o stazioni
- 🎛️ **Preimpostazioni** — Configurazioni predefinite (Personalizzato / Magazzino centrale / Giants standard)
- ⏱️ **Intervallo di aggiornamento** — Configurabile (5s / 15s / 30s / 60s / 120s / manuale)
- 🌗 **Contrasto/Trasparenza** — Sfondo della finestra su 3 livelli (chiaro / scuro / trasparente)
- 📜 **Scorrimento con rotellina** — Scorri entrambe le liste con la rotellina del mouse
- 🌍 **Multilingue** — DE, EN, FR, IT, PT, ES

### Requisiti

- Farming Simulator 25
- Opzionale: [EverythingConstructable](https://farming-simulator.com) per la funzione fabbisogno cantiere (il mod funziona anche senza, la funzione resta semplicemente nascosta)

### Installazione

1. Scarica il file ZIP
2. Estrailo nella cartella mods: `Documents/My Games/FarmingSimulator2025/mods/`
3. Attiva il mod nel gioco
4. **Shift+C** per mostrare/nascondere la DispoList (configurabile nelle impostazioni)
5. **F9 / F12** per il controllo con il mouse (secondo l'impostazione del HL HUD System)

### Controlli

| Azione | Tasto / Mouse |
|---|---|
| Mostra/nascondi DispoList | `Shift + C` (configurabile) |
| Controllo con il mouse | `F9 / F12` (HL HUD System) |
| Apri il menu impostazioni | Clic sull'icona impostazioni nella barra delle icone |
| Mostra/nascondi colonne | Menu impostazioni → «Mostra colonne» |
| Vista magazzino (dettaglio) | Clic sulla riga di un prodotto |
| Assegna zona | HUD filtro → clic sul prodotto, poi clic sulla zona di destinazione |
| Crea zona | Pulsante «+ Neuer Bereich» — prima riga dell'elenco zone |
| Rinomina/elimina zona | Clic destro su una zona → menu contestuale |
| Ordina per valore ↔ A–Z | Clic sull'icona di ordinamento (l'ordinamento per valore mette in pausa l'aggiornamento) |
| Contrasto/trasparenza | Clic sull'icona contrasto nella barra delle icone |
| Scorri le liste | Rotellina del mouse |
| Attiva/disattiva CW only | Icona stella ⭐ nella barra delle icone |
| Attiva/disattiva fabbisogno cantiere | Clic sulla riga di spiegazione della quantità libera nell'HUD principale (visibile solo con EverythingConstructable) |
| Intervallo di aggiornamento | Configurabile nel menu impostazioni |

### Menu impostazioni

Un clic sull'**icona impostazioni** nella barra delle icone apre il menu impostazioni — tutte le opzioni in un unico posto:

- **Mostra colonne** — attiva/disattiva ogni colonna singolarmente: Scorte, Libero, Prezzo/1000l, Max/1000l, Valore, Valore libero, Max €, Max libero, Miglior mese
- **Buffer di produzione** — imposta con `[−]` / `[+]` quante ore di scorta restano in magazzino prima che un prodotto sia considerato «libero» (formula: Scorte − Fabbisogno/h × Buffer = quantità libera)
- **Tipi di deposito** — decidi cosa viene conteggiato (magazzino centrale, sili, estensioni sili, allevamenti, cumuli di letame, trincee, deposito oggetti, uscite di produzione); vengono mostrati solo i tipi realmente presenti sulla tua mappa
- **Preimpostazione zone** — «Configura da solo» (nessuna modifica), «Carica preimpostazione magazzino centrale» o «Carica standard Giants»

> 💡 **Buono a sapersi:** Non appena ordini la lista per **valore** (clic sull'icona di ordinamento), l'aggiornamento automatico si mette in pausa e mostra «In pausa». È voluto — altrimenti le righe cambierebbero posto a ogni aggiornamento e la lista ti «scapperebbe». Torna su **A–Z** e l'aggiornamento riprende normalmente.

> 🏗️ **Fabbisogno cantiere:** Se [EverythingConstructable](https://farming-simulator.com) è installato, sopra la spiegazione della quantità libera appare una riga aggiuntiva «Buffer di fabbrica / cantiere». La frase sottostante mostra automaticamente se il fabbisogno cantiere viene attualmente detratto — clicca per attivare/disattivare.

### Multigiocatore

In linea di principio compatibile MP — ogni giocatore ha bisogno del mod. **Non testato ufficialmente**, uso a proprio rischio.

### Crediti

- **HappyLooser** — Framework HL HUD System (gentilmente autorizzato all'integrazione — grazie mille per il consenso!)
- **FedAction** — Mappa NF Marsch & ispirazione per il filtro magazzino centrale
- **LazyChilla** — Sviluppo del mod

---

## 🇵🇹 Português <a name="português"></a>

### ⚠️ Antes de estranhar (armadilhas comuns)

- **« O valor total mal se mexe quando vendo / parece alto demais »** → Por padrão a DispoList conta **todos** os tipos de armazenamento — incluindo estábulos e saídas de produção em **todo o mapa**. Vender algumas paletes locais quase não afeta esse monte global. **Dica:** nas definições, ative apenas os tipos de armazenamento que realmente precisa (ex. só armazém central + silos).
- **« Os valores não atualizam »** → Ao ordenar por **valor**, a atualização automática pausa de propósito (senão a lista fica a saltar). Mostra « Pausado ». Volte para **A–Z** e retoma.
- **« Tudo mostra 0 / nada é visível »** → Normalmente estão ativos os tipos de armazenamento errados. O HUD agora avisa-o ele próprio (« Verifique os tipos de armazenamento ativos »).
- **« Melhor mês não mostra nada »** → Só são mostradas as mercadorias cujo **melhor mês de venda é agora**. Alguns meses não têm pico — então fica vazio. Não é um erro, é só o calendário. 😉
- **« Livre está mais baixo do que esperado mesmo tendo bastante estoque »** → Verifique se tem uma obra aberta com [EverythingConstructable](https://farming-simulator.com) — a DispoList deduz automaticamente a sua necessidade de material da quantidade livre (ver lista de funcionalidades abaixo), visível como uma segunda linha acima da lista de produtos.

---

### O que é DispoList?

DispoList é um mod HUD para Farming Simulator 25 que fornece uma visão geral rápida dos seus estoques e os melhores preços de venda — diretamente no jogo, sem menus.

Característica especial: Os **produtos livres** são calculados automaticamente — o que as suas produções geram e não processam internamente. O buffer de produção é configurável. Veja de relance o que pode vender ou entregar.

### Funcionalidades

- 🔄 **Produtos livres** — Cálculo automático do que está disponível das produções para venda/transporte
- 📦 **Estoque** — Estoque atual e capacidade livre por produto
- 🔎 **Vista de armazenamento** — Clique num produto para ver em que armazém está e quanto (armazém central, silos, estábulos, saídas de produção, etc.)
- 🧮 **Tipos de armazenamento selecionáveis** — Decida o que é contado (armazém central, silos, extensões de silo, estábulos, montes de estrume, silos-trincheira, armazém de objetos, saídas de produção)
- 💰 **Melhores preços** — Melhor e máximo preço de venda por produto e mês
- 🔵 **Destaque azul** — As mercadorias cujo melhor mês de venda é agora aparecem a **azul** — é quando vale mais a pena vender
- 🏗️ **Necessidade de obra** — Opcional, com [EverythingConstructable](https://farming-simulator.com): reserva automaticamente o material ainda necessário para obras abertas da quantidade livre (além do buffer de fábrica), para não vender por engano material de que precisa para a sua obra. Alternável diretamente clicando na linha de explicação da quantidade livre no HUD principal; visível apenas se o mod estiver instalado
- 🏭 **Valor total** — Valor de todos os produtos livres por estação
- 🗂️ **Zonas** — Agrupe produtos em categorias personalizadas
- ✏️ **Gerir zonas** — Crie, renomeie e elimine as suas próprias zonas
- 🏪 **Estações** — Vista filtrada por estação de venda
- ⭐ **CW only** — Mostrar apenas zonas do armazém central (ideal para NF Marsch)
- 🔍 **Pesquisa** — Pesquisa rápida de produtos ou estações
- 🎛️ **Predefinições** — Configurações predefinidas (Personalizado / Armazém central / Giants padrão)
- ⏱️ **Intervalo de atualização** — Configurável (5s / 15s / 30s / 60s / 120s / manual)
- 🌗 **Contraste/Transparência** — Fundo da caixa em 3 níveis (claro / escuro / transparente)
- 📜 **Rolagem com roda do rato** — Role ambas as listas com a roda do rato
- 🌍 **Multilíngue** — DE, EN, FR, IT, PT, ES

### Requisitos

- Farming Simulator 25
- Opcional: [EverythingConstructable](https://farming-simulator.com) para a funcionalidade de necessidade de obra (o mod funciona também sem, a funcionalidade fica simplesmente oculta)

### Instalação

1. Baixe o ficheiro ZIP
2. Extraia para a pasta de mods: `Documents/My Games/FarmingSimulator2025/mods/`
3. Ative o mod no jogo
4. **Shift+C** para mostrar/ocultar a DispoList (configurável nas definições)
5. **F9 / F12** para controlo com o rato (conforme a definição do HL HUD System)

### Controlos

| Ação | Tecla / Rato |
|---|---|
| Mostrar/ocultar DispoList | `Shift + C` (configurável) |
| Controlo com o rato | `F9 / F12` (HL HUD System) |
| Abrir o menu de definições | Clique no ícone de definições na barra de ícones |
| Mostrar/ocultar colunas | Menu de definições → «Mostrar colunas» |
| Vista de armazenamento (detalhe) | Clique na linha de um produto |
| Atribuir zona | HUD de filtro → clique no produto, depois clique na zona de destino |
| Criar zona | Botão «+ Neuer Bereich» — primeira linha da lista de zonas |
| Renomear/eliminar zona | Clique direito numa zona → menu de contexto |
| Ordenar por valor ↔ A–Z | Clique no ícone de ordenação (a ordenação por valor pausa a atualização) |
| Contraste/transparência | Clique no ícone de contraste na barra de ícones |
| Percorrer as listas | Roda do rato |
| Alternar CW only | Ícone de estrela ⭐ na barra de ícones |
| Alternar necessidade de obra | Clique na linha de explicação da quantidade livre no HUD principal (visível apenas com EverythingConstructable) |
| Intervalo de atualização | Configurável no menu de definições |

### Menu de definições

Um clique no **ícone de definições** na barra de ícones abre o menu de definições — todas as opções num só lugar:

- **Mostrar colunas** — ative/desative cada coluna individualmente: Estoque, Livre, Preço/1000l, Máx/1000l, Valor, Valor livre, Máx €, Máx livre, Melhor mês
- **Buffer de produção** — defina com `[−]` / `[+]` quantas horas de reserva ficam no armazém antes de um produto contar como «livre» (fórmula: Estoque − Procura/h × Buffer = quantidade livre)
- **Tipos de armazenamento** — decida o que é contado (armazém central, silos, extensões de silo, estábulos, montes de estrume, silos-trincheira, armazém de objetos, saídas de produção); apenas os tipos realmente presentes no seu mapa são mostrados
- **Predefinição de zonas** — «Configurar por si» (sem alterações), «Carregar predefinição de armazém central» ou «Carregar padrão Giants»

> 💡 **Bom saber:** Assim que ordenar a lista por **valor** (clique no ícone de ordenação), a atualização automática pausa e mostra «Pausado». É intencional — caso contrário, as linhas trocariam de lugar a cada atualização e a lista «fugiria». Volte para **A–Z** e a atualização continua normalmente.

> 🏗️ **Necessidade de obra:** Se o [EverythingConstructable](https://farming-simulator.com) estiver instalado, aparece uma linha extra «Buffer de fábrica / obra» acima da explicação da quantidade livre. A frase abaixo mostra automaticamente se a necessidade de obra está atualmente a ser deduzida — clique para alternar.

### Multijogador

Em princípio compatível com MP — cada jogador precisa do mod. **Não testado oficialmente**, use por sua conta e risco.

### Créditos

- **HappyLooser** — Framework HL HUD System (gentilmente autorizado a integrar — muito obrigado pela autorização!)
- **FedAction** — Mapa NF Marsch & inspiração para o filtro armazém central
- **LazyChilla** — Desenvolvimento do mod

---

## 🇪🇸 Español <a name="español"></a>

### ⚠️ Antes de que te extrañes (errores comunes)

- **« El valor total apenas se mueve al vender / parece demasiado alto »** → Por defecto DispoList cuenta **todos** los tipos de almacén — incluidos establos y salidas de producción en **todo el mapa**. Vender unos palés locales apenas afecta a ese montón global. **Consejo:** en los ajustes, activa solo los tipos de almacén que realmente necesitas (p. ej. solo almacén central + silos).
- **« Los valores no se actualizan »** → Al ordenar por **valor**, la actualización automática se pausa a propósito (si no, la lista salta sin parar). Muestra « Pausado ». Vuelve a **A–Z** y sigue.
- **« Todo muestra 0 / no se ve nada »** → Normalmente están activos los tipos de almacén equivocados. El HUD ahora te lo dice él mismo (« Comprueba los tipos de almacén activos »).
- **« Mejor mes no muestra nada »** → Solo se muestran las mercancías cuyo **mejor mes de venta es ahora mismo**. Algunos meses no tienen pico — entonces queda vacío. No es un fallo, es solo el calendario. 😉
- **« Libre es menor de lo esperado aunque tengo suficientes existencias »** → Comprueba si tienes una obra abierta con [EverythingConstructable](https://farming-simulator.com) — DispoList resta automáticamente su necesidad de material de la cantidad libre (ver lista de funcionalidades abajo), visible como una segunda línea encima de la lista de productos.

---

### ¿Qué es DispoList?

DispoList es un mod HUD para Farming Simulator 25 que te ofrece una vista rápida de tus existencias y los mejores precios de venta — directamente en el juego, sin menús.

Característica especial: Los **productos libres** se calculan automáticamente — lo que tus producciones generan y no procesan internamente. El búfer de producción es configurable. Ves de un vistazo qué puedes vender o entregar.

### Funcionalidades

- 🔄 **Productos libres** — Cálculo automático de lo disponible de producciones para venta/transporte
- 📦 **Existencias** — Existencias actuales y capacidad libre por producto
- 🔎 **Vista de almacén** — Haz clic en un producto para ver en qué almacén hay cuánto (almacén central, silos, establos, salidas de producción, etc.)
- 🧮 **Tipos de almacén seleccionables** — Decide qué se cuenta (almacén central, silos, extensiones de silo, establos, montones de estiércol, silos zanja, almacén de objetos, salidas de producción)
- 💰 **Mejores precios** — Mejor y máximo precio de venta por producto y mes
- 🔵 **Resaltado azul** — Las mercancías cuyo mejor mes de venta es ahora mismo se marcan en **azul** — es cuando más conviene vender
- 🏗️ **Necesidad de obra** — Opcional, con [EverythingConstructable](https://farming-simulator.com): reserva automáticamente el material que aún se necesita para obras abiertas de la cantidad libre (además del búfer de fábrica), para no vender por error material que necesitas para tu propia obra. Se activa directamente haciendo clic en la línea de explicación de la cantidad libre en el HUD principal; solo visible si el mod está instalado
- 🏭 **Valor total** — Valor de todos los productos libres por estación
- 🗂️ **Zonas** — Agrupa productos en categorías personalizadas
- ✏️ **Gestionar zonas** — Crea, renombra y elimina tus propias zonas
- 🏪 **Estaciones** — Vista filtrada por estación de venta
- ⭐ **CW only** — Mostrar solo zonas de almacén central (ideal para NF Marsch)
- 🔍 **Búsqueda** — Búsqueda rápida de productos o estaciones
- 🎛️ **Ajustes predef.** — Configuraciones predefinidas (Personalizado / Almacén central / Giants estándar)
- ⏱️ **Intervalo de actualización** — Configurable (5s / 15s / 30s / 60s / 120s / manual)
- 🌗 **Contraste/Transparencia** — Fondo de la caja en 3 niveles (claro / oscuro / transparente)
- 📜 **Desplazamiento con rueda** — Desplaza ambas listas con la rueda del ratón
- 🌍 **Multilingüe** — DE, EN, FR, IT, PT, ES

### Requisitos

- Farming Simulator 25
- Opcional: [EverythingConstructable](https://farming-simulator.com) para la función de necesidad de obra (el mod funciona también sin él, la función simplemente queda oculta)

### Instalación

1. Descarga el archivo ZIP
2. Extráelo en tu carpeta de mods: `Documents/My Games/FarmingSimulator2025/mods/`
3. Activa el mod en el juego
4. **Shift+C** para mostrar/ocultar la DispoList (configurable en los ajustes)
5. **F9 / F12** para el control con el ratón (según el ajuste del HL HUD System)

### Controles

| Acción | Tecla / Ratón |
|---|---|
| Mostrar/ocultar DispoList | `Shift + C` (configurable) |
| Control con el ratón | `F9 / F12` (HL HUD System) |
| Abrir el menú de ajustes | Clic en el icono de ajustes en la barra de iconos |
| Mostrar/ocultar columnas | Menú de ajustes → «Mostrar columnas» |
| Vista de almacén (detalle) | Clic en la fila de un producto |
| Asignar zona | HUD de filtro → clic en el producto, luego clic en la zona de destino |
| Crear zona | Botón «+ Neuer Bereich» — primera fila de la lista de zonas |
| Renombrar/eliminar zona | Clic derecho en una zona → menú contextual |
| Ordenar por valor ↔ A–Z | Clic en el icono de orden (el orden por valor pausa la actualización) |
| Contraste/transparencia | Clic en el icono de contraste en la barra de iconos |
| Desplazar las listas | Rueda del ratón |
| Alternar CW only | Icono de estrella ⭐ en la barra de iconos |
| Alternar necesidad de obra | Clic en la línea de explicación de la cantidad libre en el HUD principal (visible solo con EverythingConstructable) |
| Intervalo de actualización | Configurable en el menú de ajustes |

### Menú de ajustes

Un clic en el **icono de ajustes** en la barra de iconos abre el menú de ajustes — todas las opciones en un solo lugar:

- **Mostrar columnas** — activa/desactiva cada columna individualmente: Existencias, Libre, Precio/1000l, Máx/1000l, Valor, Valor libre, Máx €, Máx libre, Mejor mes
- **Búfer de producción** — ajusta con `[−]` / `[+]` cuántas horas de reserva quedan en el almacén antes de que un producto cuente como «libre» (fórmula: Existencias − Demanda/h × Búfer = cantidad libre)
- **Tipos de almacén** — decide qué se cuenta (almacén central, silos, extensiones de silo, establos, montones de estiércol, silos zanja, almacén de objetos, salidas de producción); solo se muestran los tipos que existen realmente en tu mapa
- **Preajuste de zonas** — «Configurar tú mismo» (sin cambios), «Cargar preajuste de almacén central» o «Cargar estándar Giants»

> 💡 **Bueno saberlo:** En cuanto ordenas la lista por **valor** (clic en el icono de orden), la actualización automática se pausa y muestra «Pausado». Es intencional — de lo contrario, las filas cambiarían de lugar en cada actualización y la lista se te «escaparía». Vuelve a **A–Z** y la actualización continúa con normalidad.

> 🏗️ **Necesidad de obra:** Si [EverythingConstructable](https://farming-simulator.com) está instalado, aparece una línea adicional «Búfer de fábrica / obra» encima de la explicación de la cantidad libre. La frase debajo muestra automáticamente si la necesidad de obra se está deduciendo actualmente — haz clic para alternar.

### Multijugador

En principio compatible con MP — cada jugador necesita el mod. **No probado oficialmente**, úsalo bajo tu propia responsabilidad.

### Créditos

- **HappyLooser** — Framework HL HUD System (amablemente autorizado para la integración — ¡muchas gracias por el visto bueno!)
- **FedAction** — Mapa NF Marsch & inspiración para el filtro almacén central
- **LazyChilla** — Desarrollo del mod

---

*Built with ❤️ for the FS25 community*
