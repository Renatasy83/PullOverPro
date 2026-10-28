# 0.5.9~launcher1 — lansare Safari din NewTerm

## Baza verificată

0.5.8~picker1 (9bde2538367754343153c32becbc913254bc76c7), build GitHub Actions 40516923431: analiza Clang, testele parserului/persistenței, compilarea și verificările pachetului au trecut. Utilizatorul confirmă lista de 443 intrări, navigarea, selecția persistentă după respring, lock/unlock și absența PPO pe ecranul blocat.

Această etapă adaugă doar utilitarul manual /var/jb/usr/bin/ppo-open. Tweak.xm și PPOAppData.mm rămân identice cu baseline-ul 0.5.8. UI afișează în continuare 0.5.8. Nu există buton nou de lansare și utilitarul nu pornește automat. Dezvoltarea este pe debug/app-launcher; main, beta-development și ramurile testate rămân intacte.

## API și limite

Utilitarul rulează ca mobile, în proces separat de SpringBoard, cu alarm de 20 secunde. Încarcă framework-ul de sistem MobileCoreServices dacă LaunchServices nu este deja prezent. Aceasta este aceeași cale de încărcare testată de ppo-apps.

--probe inspectează +defaultWorkspace și -openApplicationWithBundleID: fără să le invoce. Afișează encodările și dacă ABI-ul se potrivește formelor suportate. Nu citește aplicațiile instalate sau selecția și nu solicită lansare.

--launch reface verificarea. Acceptă doar getter cu retur obiect, self și selector; metoda de lansare trebuie să returneze exact BOOL pentru platforma compilată și să primească exact un argument obiect. Sunt verificate și tipurile self/selector. Getter-ul urmează convenția Cocoa +0, aceeași ca în enumerator. După obținerea workspace-ului se verifică și metoda clasei reale a obiectului înainte de apelul tipizat. Existența selectorului singură nu permite lansarea.

Nu avem încă un raport de pe telefon pentru semnătura metodei de lansare. Dacă ABI-ul diferă, utilitarul refuză apelul. Testele CI folosesc o clasă fictivă pentru forme corecte și greșite ale metodelor, fără să apeleze LaunchServices.

Primul test este limitat la Safari (com.apple.mobilesafari), selectat în panoul PPO și prezent în raportul local validat. Nu acceptă bundle ID sau comenzi arbitrare din argv. Nu rulează ca root și nu adaugă entitlement-uri. Nu scrie fișiere și nu schimbă preferințe.

Un rezultat BOOL pozitiv înseamnă doar acceptarea raportată a cererii. Utilizatorul trebuie să confirme vizual deschiderea Safari. Lansarea normală nu reprezintă găzduire într-o fereastră flotantă. Cererea poate implica servicii sistem; izolarea procesului nu garantează absența efectelor asupra acestora.

## Test pe telefon, după CI verde pentru commit-ul exact

Păstrează .deb-ul funcțional 0.5.8 pentru revenire. Instalează manual .deb-ul 0.5.9~launcher1 din artefactul verificat, ca actualizare a aceluiași package ID. Păstrează flag-urile PPO și nu modifica alte tweak-uri.

1. După respring, verifică panoul existent. Nicio lansare nouă nu este executată automat.
2. În NewTerm ca mobile, fără su/sudo, rulează:
   /var/jb/usr/bin/ppo-open --probe
   Trimite ieșirea. Dacă apare ABI supported: no, oprește testul.
3. Dacă ABI supported: yes, deblochează telefonul și selectează Safari din lista PPO. Așteaptă „Selectat: Safari”.
4. Rulează o singură dată:
   /var/jb/usr/bin/ppo-open --launch
5. Confirmă vizual dacă Safari se deschide. Revino în NewTerm și trimite rezultatul complet. Dacă cererea este refuzată sau apare o excepție, nu o repeta în buclă și nu încerca privilegii root.
6. Dacă utilitarul nu termină, așteaptă maximum 20 secunde sau folosește Ctrl+C. Nu face respring-uri repetate.

Selecția este citită din /var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.selection.plist cu limită 16 KiB. Raportul apps-0.5.7.json este citit cu limită 2 MiB și validat cu același cod deja testat în 0.5.8. Dacă Safari lipsește din raport, reîmprospătează o singură dată cu /var/jb/usr/bin/ppo-apps.

Recuperare: dacă terminalul răspunde, touch /var/mobile/.ppo_disable și respring manual. Dacă telefonul este blocat, procedura verificată: repornire forțată, Dopamine cu injection oprit și dezinstalare exclusiv PPO Diagnostic. Nu șterge date personale. Flag-ul nu poate întrerupe un proces deja blocat.

## Verificări și build

CI păstrează analiza UI/parserului/enumeratorului și testele 0.5.8, adaugă analiza utilitarului de lansare și teste native pentru respingerea metodelor cu retur sau argumente greșite. Compilează UI și ambele utilitare arm64/arm64e, verifică exact patru fișiere în payload-ul rootless și salvează dependențele, UUID-urile și SHA256. Nici CI, nici verificarea ABI nu confirmă funcționarea pe telefon.

Compilare locală opțională în NewTerm ca mobile, într-un director nou:
```sh
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
git clone --branch debug/app-launcher https://github.com/Renatasy83/PullOverPro.git /var/mobile/PullOverPro-launcher
cd /var/mobile/PullOverPro-launcher
export THEOS=/var/jb/var/mobile/theos
sh scripts/build-local.sh
```

După confirmarea probei și a lansării Safari vom extinde separat aplicațiile permise, apoi vom integra o acțiune explicită în panou. Hosting-ul rămâne neactivat. Licența GPL-3.0 și atribuirea originală sunt păstrate.
