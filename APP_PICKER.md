# 0.5.8~picker1 — selecție din lista reală

## Punct de plecare

Utilizatorul a rulat ppo-apps 0.5.7 din NewTerm ca mobile. Captura arată 443 entries, 0 skipped și salvarea apps-0.5.7.json. Confirmă enumerarea prin LaunchServices în procesul separat; nu certifică faptul că toate cele 443 intrări pot fi lansate. Include posibil intrări ascunse/de sistem.

Noua etapă nu schimbă utilitarul și nu adaugă apeluri private în SpringBoard. Folosește doar fișierul existent și UIKit public. main, beta-development și toate ramurile baseline rămân intacte; dezvoltare pe debug/app-picker. GPL-3.0 și atribuirea upstream rămân păstrate.

## Comportament

- Cele trei favorite fictive sunt înlocuite cu „Deschide lista”.
- La apăsare, fișierul /var/mobile/Library/Logs/PullOverPro/apps-0.5.7.json se citește și se validează într-o coadă serială separată. Nu se citește lista sau selecția la pornirea SpringBoard.
- Maximum 2 MiB de date, schema 1, sursă LaunchServices așteptată, cel mult 4096 intrări, ID-uri unice și nume/ID-uri de 1–512 caractere. Nu se execută conținutul fișierului.
- Interfața afișează 25 de aplicații per pagină într-o listă cu scroll. Butoanele Anterior/Următor schimbă pagina. Apar numele și bundle ID-ul, utile la identificarea intrărilor de sistem.
- Selectarea salvează doar numele și bundle ID-ul în /var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.selection.plist, atomic și în afara main queue. Nu modifică preferințele altor tweak-uri.
- „Selectat: …” apare după salvare; dacă salvarea eșuează apare „Selecție nesalvată”. Lista se închide. Redeschiderea listei recitește selecția și marchează intrarea cu ✓.
- După respring, selecția se recitește când deschizi lista. Nu este încă restaurată în eticheta panoului imediat după pornire.
- Închiderea mânerului în timpul încărcării invalidează afișarea întârziată. I/O nu modifică UIKit de pe worker.
- Lista lipsă, prea mare sau invalidă produce un mesaj în panou. Nu declanșează automat enumerarea.
- Panoul păstrează tema, recentrarea și diagnosticul de metadate. Atingerea unei aplicații nu o lansează și nu îi creează o scenă.

Acest build schimbă UI SpringBoard și necesită testare pe telefon. CI verifică politica de apeluri, analiza Clang pentru UI/parser/utilitar, teste native pentru parser și selecție, build arm64/arm64e și payload rootless. Nu poate simula SpringBoard sau certifica siguranța la rulare.

## Teste pe telefon

Păstrează pachetul funcțional 0.5.7 pentru revenire. Instalează manual .deb-ul 0.5.8~picker1 din artefactul CI verde pentru commit-ul exact. Flag-urile PPO existente se păstrează.

1. După respring verifică mânerul, expand/collapse, tema și recentrarea înainte de deschiderea listei.
2. Apasă „Deschide lista”. Pentru raportul existent ar trebui să apară 443 intrări, distribuite în 18 pagini, cu 18 pe ultima pagină. Lista este sortată după nume.
3. Verifică scroll-ul, pagina următoare, pagina anterioară și „Înapoi”. Testează și închiderea mânerului cât lista este deschisă.
4. Alege o aplicație cunoscută. Panoul trebuie să afișeze „Selectat: …”, iar aplicația nu trebuie să se deschidă.
5. Redeschide lista și verifică ✓ lângă alegere pe pagina corespunzătoare. Repetă după un respring pentru a testa persistența.
6. Verifică lock/unlock, schimbarea aplicației, tema deschisă/închisă și că PPO nu apare pe ecranul blocat. Raportează dacă oricare comportament diferă de baseline.
7. Dacă lista nu e disponibilă, rulează o singură dată în NewTerm, ca mobile:
   /var/jb/usr/bin/ppo-apps
   Apoi redeschide lista. Utilitarul este păstrat identic cu 0.5.7; raportul rămâne apps-0.5.7.json.

Nu trimite întregul inventar al aplicațiilor; pentru test sunt suficiente numărul intrărilor, rezultatul selectării/persistenței și eventual o captură fără date pe care nu vrei să le partajezi.

Recuperare: dacă terminalul răspunde, touch /var/mobile/.ppo_disable și respring manual. Dacă telefonul este blocat, repornire forțată, Dopamine cu injection oprit și dezinstalarea exclusivă a PPO Diagnostic. Nu șterge preferințe sau date personale și nu repeta respring-uri în buclă. Flag-ul nu poate întrerupe un SpringBoard deja blocat.

## Build local opțional

În NewTerm ca mobile, într-un director nou:
```sh
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
git clone --branch debug/app-picker https://github.com/Renatasy83/PullOverPro.git /var/mobile/PullOverPro-picker
cd /var/mobile/PullOverPro-picker
export THEOS=/var/jb/var/mobile/theos
sh scripts/build-local.sh
```

După validarea acestei etape urmează lansarea explicită într-un proces separat sau printr-un API verificat. Hosting-ul rămâne separat și necesită cercetare de lifecycle, input și scene; nu este activat de această versiune.
