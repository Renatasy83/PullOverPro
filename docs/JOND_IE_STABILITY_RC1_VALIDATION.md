# PullOver Pro — candidat de stabilitate 3.0.2~rc1

Corecții implementate pe sursa Jond_ie, păstrând interfața originală. Este o versiune derivată independentă, nu o lansare oficială Jond_ie. Autor original: c1d3r / Will Smillie; portare rootless: Jond_ie; licență GPL-3.0.

## Pachet și sursă

- DEB: `com.johndie.pulloverpro-rootless_3.0.2~rc1_iphoneos-arm64.deb` — 92432 bytes.
- SHA256: `b3f8fc9a946ea4d87a7c0a8bd5649ab8deef54b6fe05c026f6e2ab2b3bb9b50d`.
- [Pachet arhivat](../candidate-packages/jondie-stability-3.0.2-rc1/com.johndie.pulloverpro-rootless_3.0.2~rc1_iphoneos-arm64.deb); [sume de control](../candidate-packages/jondie-stability-3.0.2-rc1/SHA256SUMS).
- Sursă compilată: [22adc654e237d21d26a67535a994f63c4980b4bd](https://github.com/Renatasy83/PullOverPro/tree/22adc654e237d21d26a67535a994f63c4980b4bd/jondie-port).
- Bază upstream: [076da8f07e707453bc58ed9baadeefb40f0e93e4](https://github.com/Jond-ie/pulloverpro/tree/076da8f07e707453bc58ed9baadeefb40f0e93e4).
- [GitHub Actions reușit](https://github.com/Renatasy83/PullOverPro/actions/runs/45205953764), job137801616407. Artefact DEB14833169352; dovezi14833367214.
- Ramură de dezvoltare: `improve/jondie-stability`; arhivă: `candidate/jondie-stability-3.0.2-rc1`. Main, ramurile stabile și arhivele anterioare sunt păstrate.

## Confirmare de pe dispozitiv — 2026-11-23

Utilizatorul a răspuns „Funcționează” după livrarea acestui candidat, pe configurația declarată anterior: iPhone12,5 / iOS26.0.1 (23A355) / Dopamine / ElleKit1.2. Aceasta consemnează funcționarea raportată de utilizator pentru pachetul livrat. Mesajul nu documentează separat cele trei probe, aplicațiile testate, stabilitatea îndelungată, consumul bateriei sau performanța; acele rezultate nu sunt presupuse.

DEB-ul, sursa compilată și dovezile automate sunt păstrate integral. Punct de revenire: `checkpoint/user-reported-working-jondie-3.0.2-rc1`. [Înregistrarea confirmării](device-confirmations/jondie-3.0.2-rc1-2026-11-23.json). Această actualizare modifică doar documentația, fără recompilare sau schimbarea pachetului.

## Ce s-a schimbat

Calculul pentru tastatură folosește cadrul final în coordonatele ferestrei și limitele vizibile. Mutarea deliberată a mânerului nu mai este anulată când dispare tastatura. Pornirea folosește o singură cerere, un singur timer și anularea rezultatelor vechi; termenul de20secunde limitează doar pornirea, fără să închidă o fereastră funcțională. Eșecul afișează o acțiune de reîncercare.

Inițializarea scenei restaurează starea anterioară dacă presenterul/fereastra nu poate fi creată. Închiderea sau schimbarea controllerului anulează pornirile și selecțiile întârziate. QuickSwitch validează selecția și păstrează listele lungi în zona vizibilă, cu derulare la margine. Preferințele sunt validate în memorie, fără rescrierea sau ștergerea datelor salvate. Semnăturile private existente sunt păstrate; nu sunt introduse API-uri private noi.

## Verificări executate

| Verificare | Rezultat |
| --- | --- |
| Șase suite automate pe macOS | Trecute: startup, tastatură, QuickSwitch, preferințe, ContextHostManager, integritatea semnăturilor |
| ContextHostManager real compilat contra interfețelor false | 66 verificări: rollback, reutilizare, curățare, erori/callbackuri și firul principal |
| Fixture pentru semnături | 13 metode de test plus cazuri de structură/corupere; detectează pagini, directoare alternative și metadate modificate |
| Clang static analyzer | 10 unități de producție, zero constatări |
| Theos release | Rootless, SDK16.5, deployment15.0; arm64 și arm64e ABI modern0x80000002 |
| Inspecție DEB | Căi rootless, filtru numai SpringBoard, preferințe/resurse, licență/proveniență, fără scripturi de instalare |
| Integritate CodeDirectory ldid | Toate directoarele primare/alternative și special slots;216 verificări de hash ale paginilor, incluzând directoarele alternative |
| Descărcare și reverificare independentă pe Linux | ZIP-uri comparate cu digesturile Actions; DEB comparat cu SHA256 și inspectat din nou |

Compilatorul a emis patru avertismente ale linkerului despre opțiunea veche `-multiply_defined`; compilarea a reușit. Jurnalele complete și rapoartele JSON sunt în [dovezile arhivate](../candidate-packages/jondie-stability-3.0.2-rc1/evidence/VALIDATION.json).

Verificatorul macOS `codesign` raportează binarele ldid ca nesemnate. Același format (flags0, fără CMS, directoare SHA1+SHA256) a fost verificat în binarele originale3.0.1. Păstrăm formatul de semnare și verificăm riguros hashurile încorporate; aceasta nu dovedește identitatea Apple sau acceptarea pe iPhone. Rezultatul macOS este păstrat explicit în [MACOS_CODESIGN_DIAGNOSTIC.json](../candidate-packages/jondie-stability-3.0.2-rc1/evidence/MACOS_CODESIGN_DIAGNOSTIC.json).

## Ce nu a putut fi executat

Asistentul nu a executat SpringBoard/UIKit pe un telefon. Ulterior verificărilor automate, utilizatorul a raportat funcționarea candidatului pe configurația declarată; sfera confirmării este descrisă mai sus. Nu s-au măsurat consumul bateriei sau performanța. Testele cu interfețe false verifică logica proprie, fără să valideze contractele private ale sistemului real. Conținutul aplicațiilor, atingerile, coordonatele tastaturii și ciclul real al scenelor necesită evaluare pe telefon; mesajul primit nu detaliază rezultatele individuale. Nu se declară compatibilitatea tuturor aplicațiilor.

## Instalare, probă și revenire

Pachetul are același identificator `com.johndie.pulloverpro-rootless` și actualizează portarea Jond_ie, păstrând domeniul preferințelor. Dacă este încă instalat vechiul `com.renatasy83.pulloverpro.diagnostic`, acesta trebuie dezinstalat manual înainte; conflictul previne injectarea ambelor. Nu șterge preferințele. Instalează manual candidatul cu Sileo/Filza, apoi fă un respring manual după instalarea reușită.

Planul de probe livrat inițial este păstrat mai jos ca referință. Confirmarea generală a fost primită; nu se solicită repetarea probelor doar pentru această actualizare a documentației.

Probele inițiale:

1. Din NewTerm sau altă aplicație, deschide o favorită în PPO fără lansare normală prealabilă. Verifică atingeri/derulare, închidere/redeschidere și păstreaz-o deschisă peste30secunde. Închide imediat după o selecție o singură dată: nu trebuie să se redeschidă singură.
2. Arată/ascunde tastatura; verifică mânerul pe ambele margini. Mută-l manual cât timp tastatura este vizibilă, apoi ascunde tastatura: poziția aleasă trebuie păstrată.
3. Verifică selectarea/anularea în QuickSwitch și, dacă lista este lungă, derularea la margine. Verifică o schimbare din Configurări și ținta pentru deschidere pe tot ecranul.

Aplicația deja afișată pe tot ecranul nu poate fi găzduită simultan în această bază upstream; proba pornește din altă aplicație. Nu este necesară testarea exhaustivă a fiecărei aplicații sau provocarea artificială a unei erori.

Păstrează [DEB-ul original upstream3.0.1 pentru revenire](https://raw.githubusercontent.com/Jond-ie/repo/84183ec8b6c3bce2d777575264d4380ebf6740f1/debs/com.johndie.pulloverpro-rootless_3.0.1_iphoneos-arm64.deb). Copia descărcată a fost comparată cu SHA256 `65c5cffbb07fdbde599c8d11b4ab95301702de0bdd92b1da35fd8c7a2d4d5895`; funcționarea ei pe acest telefon nu a fost confirmată în conversație. Revenirea este un downgrade manual. Dacă SpringBoard se blochează, folosește procedura deja cunoscută: reboot, Dopamine fără tweak injection, apoi elimină doar candidatul sau revino manual. Nicio instalare, respring, ștergere de date sau modificare a altor tweak-uri nu a fost executată automat.
