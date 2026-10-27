# 0.5.7~enumerator1 — enumerare izolată, pornită din NewTerm

## Dovezi și limite

Raportul 0.5.6 primit de la telefon confirmă în SpringBoard:
- LSApplicationWorkspace +defaultWorkspace și -allInstalledApplications: @16@0:8.
- LSApplicationProxy -applicationIdentifier, -bundleIdentifier și -localizedName: @16@0:8.
- SBApplication -bundleIdentifier și -displayName sunt prezente; -displayIdentifier lipsește.

Encodarea indică retur obiect, self și selector, fără argumente explicite. Nu dovedește semantica, accesul permis, ownership sau absența blocajelor. Utilitarul reverifică encodarea exactă înainte de fiecare apel, în procesul său. Pentru aceste accesorii se aplică convenția Cocoa de retur +0; funcționarea efectivă rămâne de verificat pe telefon. Folosește doar LaunchServices; nu apelează SBApplicationController și nu revine automat la alte API-uri.

Codul Tweak.xm este IDENTIC cu 0.5.6 metadata1. Nu există enumerare nouă în SpringBoard, nici pornire automată a utilitarului. Pachetul adaugă executabilul rootless /var/jb/usr/bin/ppo-apps, semnat normal, fără entitlement-uri suplimentare. În SpringBoard eticheta/logul 0.5.6 este păstrată intenționat; versiunea pachetului este 0.5.7~enumerator1.

Pe firul principal al utilitarului se încarcă, dacă este necesar, framework-ul sistem MobileCoreServices, apoi se verifică API-urile și se face o singură solicitare allInstalledApplications. Nu se forțează încărcarea vreunui framework în SpringBoard. Un alarm de 20 de secunde închide doar utilitarul dacă nu termină. Cererea poate implica serviciul LaunchServices; izolarea nu garantează că serviciile sistemului nu pot fi afectate. Nu sunt retry-uri și nu se solicită privilegii root.

Returul trebuie să fie NSArray, cu cel mult 4096 de intrări; obiectele și șirurile sunt validate, ID-urile duplicate eliminate. Rezultatul poate include intrări de sistem sau ascunse: nu presupunem că fiecare poate fi lansată. Nu sunt enumerate iconițe, nu se lansează aplicații și nu se creează scene. Lista reală nu este încă afișată în panou.

Singurul fișier scris este raportul propriu /var/mobile/Library/Logs/PullOverPro/apps-0.5.7.json. Conține numele și bundle ID-urile aplicațiilor și rămâne pe telefon. O nouă execuție reușită îl înlocuiește atomic. Nu trebuie trimis întregul fișier pentru testul inițial; numărul intrărilor și mesajul de succes sunt suficiente.

## Test manual

1. Păstrează pachetul funcțional 0.5.6 sau 0.5.5 pentru revenire. Instalează manual numai noul .deb 0.5.7~enumerator1 din CI verde, ca actualizare a aceluiași package ID. Nu schimba flag-urile PPO sau alte tweak-uri.
2. După respring, verifică panoul existent. Noul utilitar nu a fost executat încă.
3. În NewTerm, ca mobile (nu su, nu sudo), rulează:
   /var/jb/usr/bin/ppo-apps
4. Trimite doar mesajul rezultat (număr intrări și intrări omise, ori eroare). Pentru a vedea lista reală local, deschide /var/mobile/Library/Logs/PullOverPro/apps-0.5.7.json în Filza.
5. Dacă utilitarul nu răspunde, așteaptă maximum 20 de secunde sau folosește Ctrl+C. Nu repeta comanda în buclă; raportează mesajul terminalului. Dacă este raportată o eroare de acces, nu schimba permisiuni și nu rula ca root.
6. În cazul unui blocaj al telefonului, păstrează procedura verificată: repornire forțată, Dopamine cu injection oprit, dezinstalare exclusiv PPO Diagnostic. Nu șterge date personale.

După confirmarea enumerării vom integra citirea fișierului JSON în panou, cu selectarea aplicațiilor reale. Lansarea și hosting-ul rămân etape separate.

## Build

CI analizează separat utilitarul și tweak-ul, compilează ambele arm64/arm64e, verifică exact cele trei fișiere din payload-ul rootless și exportă dependențe, UUID-uri, SHA256. Nu poate valida funcționarea LaunchServices pe telefon.

Compilare opțională în NewTerm, într-un director nou:
```sh
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
git clone --branch debug/app-enumerator https://github.com/Renatasy83/PullOverPro.git /var/mobile/PullOverPro-enumerator
cd /var/mobile/PullOverPro-enumerator
export THEOS=/var/jb/var/mobile/theos
sh scripts/build-local.sh
```

main, beta-development și baseline-urile debug/safe4-startup și debug/app-metadata rămân nemodificate. Licența GPL-3.0 și atribuirea originală rămân păstrate.
