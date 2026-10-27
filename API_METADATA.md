# 0.5.6~metadata1 — diagnostic API, fără apeluri private

## Baza confirmată

0.5.5~diagnostic1, commit 66df0c08a3b983f96119e335fc5f20c28377e3e5: utilizatorul a testat panoul, glisarea, favoritele, tema, recentrarea și lock/unlock. Raportează funcționare normală și absența PPO pe ecranul blocat. Nu este o validare a găzduirii aplicațiilor sau o explicație a crash-urilor anterioare.

Captura NewTerm furnizată în conversație arată sw_vers: iPhone OS 26.0.1, build 23A355; sysctl: hw.machine iPhone12,5 și kern.osversion 23A355; dpkg-query: ellekit 1.2. Confirmăm ieșirile afișate; acestea nu verifică independent versiunea Dopamine. Rapoartele .ips inițiale încă lipsesc.

Baseline-ul rămâne pe debug/safe4-startup, main și beta-development rămân neschimbate. Această etapă este pe debug/app-metadata.

## Ce se schimbă

Un singur buton „Diagnostic API” și spațiu suplimentar în panou. După apăsare, maximum o dată per proces SpringBoard:
- Citește metadate din zece perechi clasă/metodă din SBApplicationController, SBApplication, LSApplicationWorkspace și LSApplicationProxy.
- Folosește objc_lookUpClass, sel_registerName, class_getClassMethod/class_getInstanceMethod și method_getTypeEncoding. Nu trimite mesaje acelor clase și nu creează instanțe.
- Nu încarcă framework-uri, nu execută implementările private și nu enumeră aplicații. Semnăturile obținute nu stabilesc ownership, threading, entitlement-uri sau comportamentul.
- Produce raportul în worker queue; nu mută apeluri private SpringBoard pe worker. UIKit este actualizat numai pe main queue.
- Scrie exclusiv raportul propriu /var/mobile/Library/Logs/PullOverPro/metadata-0.5.6.txt și loghează rezultatul salvării. Raportul nu conține aplicațiile instalate sau identificatori personali. O nouă rulare după respring înlocuiește doar acest raport.
- La pornire nu se citește nicio metadată privată. Flag-urile și mecanismul de overlay rămân cele ale baseline-ului.

GPL-3.0 și atribuirea upstream rămân păstrate. CI: policy checks, Clang analyzer, build arm64/arm64e, payload rootless și UUID-uri. Build verde nu garantează siguranța la rulare.

## Test de pe telefon

Păstrează .deb-ul funcțional 0.5.5 pentru revenire. Descarcă artefactul CI verde pentru commit-ul exact al acestei ramuri. Instalează manual doar com.renatasy83.pulloverpro.diagnostic, versiunea 0.5.6~metadata1. Nu instala alte tweak-uri. Flag-ul .ppo_enable_overlay deja creat continuă să funcționeze; .ppo_disable are prioritate.

1. După instalare și respring, verifică întâi funcțiile vechi, fără să apeși butonul nou.
2. Dacă telefonul este stabil, apasă o dată „Diagnostic API”. Ar trebui să apară „Raport API salvat (Filza)”.
3. În Filza deschide /var/mobile/Library/Logs/PullOverPro/metadata-0.5.6.txt și trimite fișierul în conversație. Se poate citi și în NewTerm:
   cat /var/mobile/Library/Logs/PullOverPro/metadata-0.5.6.txt
4. Dacă apare „Raport API: eroare”, raportează mesajul; nu modifica permisiunile directoarelor. Dacă butonul nu răspunde, nu apăsa repetat și nu face respring-uri în buclă.
5. Recuperare: touch /var/mobile/.ppo_disable și respring manual dacă terminalul funcționează. Dacă telefonul este blocat, procedura deja reușită: repornire forțată, Dopamine cu injection oprit, dezinstalarea exclusivă a PPO Diagnostic. Nu șterge date personale.

Comenzi de compilare locală, numai dacă alegi această variantă, în NewTerm ca mobile și într-un director nou:
```sh
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
git clone --branch debug/app-metadata https://github.com/Renatasy83/PullOverPro.git /var/mobile/PullOverPro-metadata
cd /var/mobile/PullOverPro-metadata
export THEOS=/var/jb/var/mobile/theos
sh scripts/build-local.sh
```

Următoarea etapă se stabilește după analiza raportului. Nu activa enumerarea, lansarea sau hosting-ul doar pentru că un selector există.
