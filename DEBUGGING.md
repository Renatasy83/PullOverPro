# PullOver Pro 0.5.5 diagnostic1

## Ce știm și ce nu știm

Referințe inspectate la 27 octombrie 2026:

| Versiune | Commit | Dovezi |
| --- | --- | --- |
| Alpha 4 | af336d84a6b4812e6b6406af87803fb15bf29c3b | Funcționare raportată de utilizator; main rămâne neatins |
| Safe 3 | 047cd429d4e23a68eb00cc56997e0ca7cefc4772 | Funcționare raportată; CI reușit |
| Safe 4 | f2d4108213d25e940f21d8a14032cfdd08f343c4 | Blocaj raportat după build local; CI reușit |
| Safe 4 Fix 1 | 5d567129d6a584e46f2a580fd8b7263b4ded07dc | CI #28 reușit; rulare pe telefon neconfirmată |

Safe 3 → Safe 4 adaugă trei butoane și handler-ul lor, mută controalele și mărește panoul de la 228 la 310 puncte. Ambele versiuni înregistrau unele acțiuni cu ppoTarget nil; Safe 3 avea deja problema pentru Temă și Recentrare. UIKit permite target nil și caută handler-ul în responder chain la interacțiune. Ordinea este greșită pentru intenția proiectului, dar nu demonstrează cauza blocajului la logo. Fix 1 corectează ordinea; nu confirmă cauza.

În toate aceste versiuni, fereastra globală era publicată înainte de finalizarea construcției. Lipsa scenei active abandona definitiv instalarea. Kill switch-ul din constructor nu garanta omiterea hook-ului Logos generat automat. Acestea sunt probleme de robustețe, nu cauze demonstrate ale watchdog-ului.

Repository-ul nu conține rapoartele SpringBoard-2026-10-26-135206.ips, SpringBoard-2026-10-26-135306.ips sau userspace-panic-1793015646.ips. Nu au fost analizate direct în această sesiune. Timeout-urile sunt descrise de utilizator; nu atribuim cauza unei biblioteci sau unei excepții. Nici iPhone12,5 / iOS 26.0.1 / build / Dopamine / ElleKit 1.2 nu sunt încă verificate prin loguri. Filtrul, schema și dependențele din surse confirmă intenția de build rootless cu ElleKit, nu compatibilitatea reală a configurației relatate.

## Schimbarea de diagnostic

- Niciun hook SpringBoard și niciun apel privat: constructorul doar verifică flag-urile și programează lucrul pe coada principală. Notificarea publică UISceneDidActivateNotification poate solicita instalarea.
- Overlay dezactivat implicit; .ppo_enable_overlay îl armează la următoarea pornire SpringBoard. .ppo_disable are prioritate și nu se șterge automat.
- Cel mult trei încercări la intervale de două secunde. Lipsa scenei după aceste încercări lasă interfața oprită până la respring; nu este o eroare de injecție demonstrată.
- Obiecte locale și target puternic reținut înainte de addTarget; starea globală este publicată numai după construcție și afișare. O excepție ObjC sincronă oprește încercările; aceasta nu protejează împotriva deadlock-urilor, watchdog-ului sau fault-urilor native.
- Loguri [PPO 0.5.5]: loaded (include versiunea OS), overlay-disabled sau overlay-armed, ui-build-begin, ui-built; showing, ui-visible; eventual no-active-scene ori ui-exception. Fără loguri la fiecare pas de drag și fără lista aplicațiilor instalate în loguri.

Această versiune este o etapă de diagnostic pentru portul funcțional. Favoritele încă sunt etichete de test. Nu enumeră, nu lansează și nu găzduiește aplicații.

## Build și diferențele dintre medii

Build-ul CI #28 folosea macOS 26.6.2 arm64, Xcode/Apple clang, Theos și SDK-uri clonate din ramuri mobile și SDK latest. Inventarul conținea SDK 16.5, dar nu era tipărită comanda compilatorului cu SDK-ul efectiv. Telefonul folosește, conform utilizatorului, Procursus clang 16 / Theos 2.5 / SDK 16.5. Nu sunt build-uri identice.

Acest workflow fixează SDK 16.5 și commit-urile Theos/SDK, generează manifest cu compilatorul și SHA-urile, rulează analiza Clang pentru arm64, compilează arm64+arm64e, verifică payload-ul Debian, arhitecturile Mach-O și exportă UUID-uri, dependențe și SHA256. Nu execută SpringBoard. Rootless: iphoneos-arm64 în control și /var/jb/Library/MobileSubstrate/DynamicLibraries în payload. Dublura filtrului din layout a fost eliminată; Theos instalează filtrul din rădăcină.

/bin/sh absent este o problemă de build ce trebuie eliminată înaintea testării, nu dovada cauzei blocajului. Theos common.mk cere bash; scriptul alege un bash existent și transmite SHELL pe linia de comandă pentru sub-make; nu creează symlink-uri în sistem. LC_ALL=C și LANG=C elimină dependența de locale nesuportate. Un pachet generat în prezența erorilor make nu este acceptat ca build verificat.

Pe telefon, în NewTerm ca mobile, într-un checkout separat pentru a păstra modificările locale:

```sh
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
git clone --branch debug/safe4-startup https://github.com/Renatasy83/PullOverPro.git /var/mobile/PullOverPro-diagnostic
cd /var/mobile/PullOverPro-diagnostic
export THEOS=/var/jb/var/mobile/theos
sh scripts/build-local.sh
```

Scriptul nu instalează pachetul și nu execută respring. Dacă sub-make încă reclamă /bin/sh, oprește testul și furnizează jurnalul complet, inclusiv prima eroare. Nu modifica alte tweak-uri. Artefactul CI este preferat pentru primul test comparabil; verifică versiunea 0.5.5~diagnostic1 și SHA-ul build-ului, nu vechea etichetă Safe2 a artefactelor anterioare.

## Test pe telefon și recuperare

Continuă numai după CI verde pentru commit-ul exact și după salvarea rapoartelor existente. Instalarea este manuală prin Sileo/Filza. Păstrează disponibil pachetul funcțional 0.5.2, fără a instala simultan altă variantă a tweak-ului. Numele „Safe” al versiunilor anterioare nu garantează siguranța.

1. În NewTerm ca mobile: touch /var/mobile/.ppo_disable înainte de instalarea manuală. După respring trebuie să apară logul loaded și overlay-disabled, fără panou. Observă telefonul cel puțin trei minute, apoi lock/unlock. Chiar și încărcarea unei biblioteci implică un test real, nu o garanție de recuperare.
2. Numai dacă etapa 1 funcționează: creează flag-ul touch /var/mobile/.ppo_enable_overlay. Înlătură exclusiv kill switch-ul creat pentru PPO cu rm /var/mobile/.ppo_disable, apoi respring manual. Nu modifica alte fișiere. Testează panou deschis/închis, drag, toate cele trei favorite, Temă, Recentrare, lock/unlock și schimbarea aplicației. Raportează dacă există interfață pe lockscreen; nu extinde testul cu API-uri private de lock.
3. Dacă UI nu apare, trimite logurile [PPO 0.5.5]; un rezultat no-active-scene nu justifică activarea forțată a unei scene private. Repetă după respring deblocat, dacă telefonul este stabil.
4. Pentru dezactivare: touch /var/mobile/.ppo_disable și respring manual. Flag-ul se verifică la încărcare și înaintea instalării; nu poate întrerupe un SpringBoard deja blocat și nu ascunde instantaneu un overlay deja creat.
5. Dacă rămâne blocat: folosește procedura deja reușită pe acest telefon — repornire forțată, Dopamine cu tweak injection oprit, dezinstalare exclusiv com.renatasy83.pulloverpro.diagnostic prin Sileo. Nu șterge preferințe sau date personale. Nu repeta respring-uri în buclă.

Trimite rezultatul separat pentru fiecare etapă, sursa pachetului, versiunea și SHA-ul. Pentru identificarea sistemului se pot rula, fără modificări:

```sh
sw_vers
uname -a
sysctl hw.machine kern.osversion
dpkg-query -W ellekit
```

Unele comenzi pot lipsi; raportează eroarea, nu instala automat dependențe. Atașează rapoartele .ips complete, inclusiv stackshot, Binary Images/usedImages și termination details; poți anonimiza identificatorii personali. Sunt necesare și raportul noului blocaj Safe 4, dacă există, și jurnalul complet al build-ului local. Rapoartele vechilor Preview nu identifică automat cauza unui incident Safe 4 ulterior.

## Etapele către funcționalitatea originală

1. Confirmarea acestui baseline pe telefon, inclusiv loguri și recuperare.
2. Inspectare separată a metadatelor runtime pentru API-urile de enumerare: clase, disponibilitate, method_getTypeEncoding, tipuri de retur și model de threading. Existența selectorului singură nu validează ABI-ul sau comportamentul. Nu apela selectori neverificați și nu muta automat API-uri SpringBoard pe un worker thread.
3. Enumerare read-only declanșată explicit, fără scanare la pornire; măsurare durată, rezultate limitate, selecție și persistență doar în fișierul propriu PPO.
4. Lansare normală explicită, validată separat de enumerare și de hosting.
5. Hosting: cercetare separată pentru lifecycle, autorizări, input și keyboard; întâi o singură aplicație, apoi ferestre multiple.

Upstream-ul c1d3r / Will Smillie este GPL-3.0; LICENSE este păstrat aici. Codul vechi folosește SBMainSwitcherViewController/recentAppLayouts și SBIconImageInfo pentru listă/iconițe; ContextHostManager folosește _scenesByID prin KVC, FBSceneLayerManager, _UIContextLayerHostView, _UIExternalSceneLayerHostView și modificări FBSMutableSceneSettings. Toate necesită reverificare pentru OS-ul efectiv. Preview-ul vechi apela allApplications și launchApplicationWithIdentifier:suspended: cu objc_msgSend presupus; nu îl reactivăm. Această etapă nu copiază în tweak acele implementări private.
