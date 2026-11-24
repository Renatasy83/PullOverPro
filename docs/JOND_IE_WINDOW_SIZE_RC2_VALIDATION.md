# PullOver Pro — redimensionare și dimensiuni per aplicație,3.0.2~rc2

Candidat derivat independent din portarea Jond_ie, cu autorii c1d3r / Will Smillie și Jond_ie creditați conform GPL-3.0. Interfața originală este păstrată, cu un mic mâner de redimensionare sub fereastră. RC1 rămâne pachetul de revenire raportat funcțional de utilizator.

## Pachet și sursă

- DEB: `com.johndie.pulloverpro-rootless_3.0.2~rc2_iphoneos-arm64.deb`,98020bytes; SHA256 `59bf2fc4426c4ed78b28654af622574fc385d50c219d61d96998f9e3582fd5e4`.
- [DEB arhivat](../candidate-packages/jondie-window-size-3.0.2-rc2/com.johndie.pulloverpro-rootless_3.0.2~rc2_iphoneos-arm64.deb); [SHA256SUMS](../candidate-packages/jondie-window-size-3.0.2-rc2/SHA256SUMS).
- [Sursa exactă compilată](https://github.com/Renatasy83/PullOverPro/tree/93b0304e39d1a97ba90eb0511d57e9e3780f95a2/jondie-port), bazată pe4c986fb7b881f9b80ce5eb747057f3b0c3153ef7 / upstream076da8f07e707453bc58ed9baadeefb40f0e93e4.
- [GitHub Actions reușit](https://github.com/Renatasy83/PullOverPro/actions/runs/45332058212), job138235302471; artefact DEB14892313021, dovezi14892058549.
- Dezvoltare: `feature/jondie-window-size`; arhivă: `candidate/jondie-window-size-3.0.2-rc2`. Main și arhivele/checkpointurile anterioare sunt păstrate.

## Comportamentul implementat

Glisează micul mâner cu săgeți diagonale de sub fereastră pentru a o micșora sau mări, cu proporțiile păstrate. Intervalul este55–100percent din cea mai mare dimensiune disponibilă în sertar. Dimensiunea implicită pe iPhone11ProMax414x896 este identică celei din RC1. Mânerul este în afara conținutului aplicației, iar redimensionarea ajustează wrapperul UIKit existent, păstrând scena găzduită. Nu sunt introduse API-uri private noi și nu se relansează aplicația pentru fiecare mișcare.

Dimensiunea se salvează doar la încheierea unei glisări valide, separat pentru fiecare bundleID. O glisare anulată prin închidere/schimbarea aplicației/controllerului nu salvează rezultatul intermediar. Dublul tap fizic restabilește dimensiunea originală numai pentru aplicația curentă. VoiceOver oferă ajustare și acțiunea Restore original size. Citirea stării nu scrie date; salvarea/resetarea păstrează celelalte aplicații, poziția mânerului și preferințele existente.

## Verificări executate

| Verificare | Rezultat |
| --- | --- |
| Opt suite automate macOS | Toate trecute: cele șase din RC1 plus geometrie și stocarea reală a dimensiunilor |
| Stocare Foundation reală |123 verificări: aplicații independente, resetare, valori invalide/clamp, citire nedistructivă, redeschiderea defaults și32 actualizări concurente |
| Geometrie reală folosită de UIKit | ASan/UBSan: dimensiunea implicită, proporții, safe area, mâner, proiecția glisării, limite și valori invalide |
| ContextHostManager real / platformă simulată |66 verificări trecute; semnăturile private existente sunt păstrate |
| Fixture semnături |13 metode de test plus cazuri de corupere/structură invalide |
| Analiză Clang |11 unități de producție, zero constatări |
| Theos release | SDK16.5/deployment15.0, rootless; arm64 și arm64e modern0x80000002 |
| Inspecție pachet | Căi, filtre SpringBoard, preferințe, GPL/proveniență, fără scripturi de instalare;228 verificări ale hashurilor de pagină, incluzând directoarele alternative |
| Descărcare și control independent Linux | ZIP-urile comparate cu digesturile Actions; DEB comparat cu SHA256 și inspectat din nou |

Au rămas patru avertismente ale linkerului despre opțiunea veche `-multiply_defined`; compilarea a reușit. Formatul ldid este neschimbat. macOS codesign îl raportează ca nesemnat, iar rezultatul este păstrat separat; integritatea hashurilor încorporate nu stabilește identitatea Apple sau acceptarea pe telefon. [Dovezi complete](../candidate-packages/jondie-window-size-3.0.2-rc2/evidence/VALIDATION.json).

## Confirmare de pe telefon și limite — 2026-11-24

După livrarea RC2, utilizatorul a răspuns „Funcționează corect”. Înregistrăm funcționarea corectă raportată pentru pachetul livrat și opțiunea de redimensionare, pe configurația declarată anterior: iPhone12,5 / iOS26.0.1 (23A355) / Dopamine rootless / ElleKit1.2. Mesajul nu enumeră separat fiecare probă, aplicațiile testate, păstrarea după respring sau stabilitatea îndelungată; rezultatele individuale nu sunt presupuse.

Punctul de revenire `checkpoint/user-reported-working-jondie-3.0.2-rc2` păstrează același DEB și dovezile. [Înregistrarea feedbackului](device-confirmations/jondie-3.0.2-rc2-2026-11-24.json). Arhiva originală RC2 și pachetul RC1 nu au fost modificate. Confirmarea anterioară RC1 rămâne în [înregistrarea ei](device-confirmations/jondie-3.0.2-rc1-2026-11-23.json).

Asistentul nu a executat verificări independente pe telefon. Testele Foundation redeschid obiecte defaults, fără să simuleze un respring iOS; feedbackul utilizatorului este consemnat separat de dovezile automate. Nu sunt stabilite compatibilitatea tuturor aplicațiilor ori beneficii măsurate de baterie/performanță.

Planul de probe livrat inițial rămâne mai jos ca referință. Nu se solicită repetarea lor doar pentru această actualizare a documentației:



1. Din NewTerm sau altă aplicație, deschide o favorită în PPO. Trage mânerul de sub fereastră; verifică derularea, un buton/link și tastarea la dimensiunea micșorată. Probează mânerul și cu cealaltă margine selectată, confirmând că nu glisează întregul sertar în loc să redimensioneze.
2. Alege dimensiuni diferite pentru două aplicații, închide/redeschide și verifică memorarea separată. Dublul tap pe mânerul uneia trebuie să restabilească numai dimensiunea ei.
3. După alegerea unei dimensiuni neimplicite, fă un respring manual și verifică păstrarea ei. Nu este necesară verificarea fiecărei aplicații.

## Instalare și revenire

Același ID `com.johndie.pulloverpro-rootless` actualizează RC1 fără ștergerea preferințelor. Instalează manual prin Filza/Sileo, apoi respring după instalarea reușită. Vechiul diagnostic `com.renatasy83.pulloverpro.diagnostic` nu trebuie injectat simultan; elimină-l manual doar dacă este prezent. Nu șterge preferințele.

Pachet de revenire: [RC1 confirmat de utilizator](https://raw.githubusercontent.com/Renatasy83/PullOverPro/6c3fdc2fe19b09d1fa5d11a5be9f0aec095fb463/candidate-packages/jondie-stability-3.0.2-rc1/com.johndie.pulloverpro-rootless_3.0.2~rc1_iphoneos-arm64.deb), SHA256 `b3f8fc9a946ea4d87a7c0a8bd5649ab8deef54b6fe05c026f6e2ab2b3bb9b50d`. Revenirea este un downgrade manual; RC1 ignoră noua cheie de dimensiuni. Dacă SpringBoard se blochează: reboot, Dopamine fără tweak injection, apoi elimină/downgradează doar candidatul. Nicio instalare, respring, terminare de proces sau ștergere a datelor personale nu a fost executată automat.
