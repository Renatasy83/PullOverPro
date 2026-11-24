# PullOver Pro — bară de mutare și poziții per aplicație,3.0.2~rc3

Utilizatorul a confirmat că redimensionarea RC2 funcționează, dar dorește o fereastră practică pe care să o poată muta liber. RC3 adaugă o bară de sus pentru mutare și închidere, păstrând mânerul de redimensionare. Este o versiune derivată independentă, GPL-3.0, cu c1d3r / Will Smillie și Jond_ie creditați. RC2 rămâne arhivat pentru revenire.

## Pachet și sursă

- DEB: `com.johndie.pulloverpro-rootless_3.0.2~rc3_iphoneos-arm64.deb`,105096bytes; SHA256 `cb7450093d305e65762d7ba1c5d68aac05f6b3ea6dfa36d9b0ac8a8aecdc19cd`.
- [DEB arhivat](../candidate-packages/jondie-window-move-3.0.2-rc3/com.johndie.pulloverpro-rootless_3.0.2~rc3_iphoneos-arm64.deb); [SHA256SUMS](../candidate-packages/jondie-window-move-3.0.2-rc3/SHA256SUMS).
- [Sursa exactă compilată](https://github.com/Renatasy83/PullOverPro/tree/7cf87439e67a7f5bb7494a04946eb72366bd220a/jondie-port), bazată pe checkpointul RC2821e91052c5f08cb82bbb1b54c9fe15a3254e529 și upstream076da8f07e707453bc58ed9baadeefb40f0e93e4.
- [Actions reușit](https://github.com/Renatasy83/PullOverPro/actions/runs/45481859945), job138756816704; artefact DEB14961898471, dovezi14962620697.
- Dezvoltare `feature/jondie-window-move`; arhivă `candidate/jondie-window-move-3.0.2-rc3`. Main și arhivele/checkpointurile RC1/RC2 sunt păstrate.

## Comenzi și comportament

Micșorează fereastra cu mânerul de jos, apoi prinde bara de sus pentru a muta întregul grup pe orizontală și verticală. Bara, aplicația și mânerul rămân în zona vizibilă. X închide. Dublul tap fizic pe bară resetează numai poziția aplicației curente; dublul tap pe mânerul de jos resetează dimensiunea maximă. VoiceOver are acțiuni direcționale și resetare.

Poziția și dimensiunea se salvează separat pentru fiecare aplicație numai după încheierea unui gest valid. Închiderea, schimbarea aplicației/controllerului sau invalidarea cadrului anulează gestul incomplet. Noua cheie `windowPositionsV1` conține poziții normalizate în spațiul disponibil; `windowSizeFractionsV1` este păstrată. Citirea nu rescrie datele; salvarea/resetarea păstrează starea celorlalte aplicații și preferințele globale.

Redimensionarea păstrează proporțiile și originea ferestrei până când limitele ecranului cer o ajustare. Scena aplicației rămâne activă: schimbarea folosește cadre/transformări UIKit deținute de tweak, fără API-uri private noi sau relansare la fiecare mișcare. Grupul este ascuns complet când sertarul este închis, inclusiv pentru ferestre mutate în vechea margine a mânerului.

Bara ocupă spațiu: pentru414x896 cu insets44/34, aplicația maximă devine354.857x768puncte, iar grupul complet are818puncte înălțime. Nu se pretinde aceeași dimensiune maximă ca RC2. O fereastră micșorată are mai mult spațiu de mișcare. Activarea de la margine și închiderea prin atingerea fundalului rămân comportamentul original; nu s-au introdus mai multe ferestre simultane.

## Verificări executate

| Verificare | Rezultat |
| --- | --- |
| Zece suite macOS | Toate trecute: opt din RC2 plus geometria grupului mobil și stocarea pozițiilor |
| Stocare reală poziții Foundation |272 verificări: două aplicații, valori invalide, citire nedistructivă, resetare, metadate/stare/dimensiuni păstrate, redeschidere și concurență |
| Stocare reală dimensiuni Foundation |123 verificări păstrate și trecute |
| Geometrie mobilă folosită în producție | ASan/UBSan: mișcare normalizată, margini complete, safe area, redimensionare ancorată, oglindire logică și valori invalide |
| ContextHostManager real / interfețe false |66 verificări trecute; implementarea găzduirii rămâne neschimbată |
| Integritate semnături |13 metode de test plus cazuri de structură/corupere;244 verificări de hash de pagină în DEB, incluzând directoarele alternative |
| Analiză Clang |12 unități de producție, zero constatări |
| Theos release și DEB | Rootless SDK16.5/deployment15.0; arm64 + arm64e modern0x80000002; căi, filtru SpringBoard, preferințe, licență/proveniență și lipsa scripturilor de instalare verificate |
| Descărcare independentă | Digesturile ZIP Actions și SHA256 DEB au coincis; inspecția pachetului s-a repetat independent pe Linux |

Au rămas patru avertismente de linker pentru opțiunea veche `-multiply_defined`; compilarea a reușit. Formatul ldid nu s-a schimbat. macOS codesign îl raportează ca nesemnat, separat de verificarea hashurilor încorporate; nu se declară identitate Apple sau acceptare pe dispozitiv. [Dovezi complete](../candidate-packages/jondie-window-move-3.0.2-rc3/evidence/VALIDATION.json).

## Limite și proba de pe telefon

RC3 nu a fost executat pe telefon. Confirmările utilizatorului se referă la RC1/RC2; pentru bara nouă nu sunt confirmate gesturile UIKit/paginarea, atingerile în conținut după mutare sau persistența după respring. Testele geometrice/Foundation nu execută scenele și intrarea remote ale SpringBoard. Nu sunt stabilite compatibilitatea tuturor aplicațiilor, stabilitatea îndelungată ori beneficii măsurate de baterie/performanță.

Probează într-o singură sesiune:

1. Din NewTerm sau altă aplicație, deschide o favorită, micșoreaz-o și mut-o prinzând bara de sus în câteva colțuri. Verifică derularea, un buton/link și tastarea după mutare; încearcă bara și pe cealaltă margine. Mânerul de jos trebuie să redimensioneze, nu să mute tot sertarul.
2. Alege poziții/dimensiuni diferite pentru două aplicații și redeschide-le. Dublul tap pe bară trebuie să reseteze poziția; dublul tap pe mânerul de jos, dimensiunea. X trebuie să închidă normal.
3. Cu o poziție mutată aleasă, fă un respring manual și verifică memorarea. Nu este necesară testarea fiecărei aplicații.

## Instalare și recuperare

Instalează manual prin Filza/Sileo și fă respring după instalarea reușită. Același ID `com.johndie.pulloverpro-rootless` actualizează RC2, păstrând preferințele. Vechiul diagnostic `com.renatasy83.pulloverpro.diagnostic` nu trebuie injectat simultan; elimină-l manual doar dacă este prezent, fără ștergerea preferințelor.

Pachet de revenire: [RC2 confirmat de utilizator](https://raw.githubusercontent.com/Renatasy83/PullOverPro/dd5e7e3ec5dd73231d65dd9e7fae18614ee8b865/candidate-packages/jondie-window-size-3.0.2-rc2/com.johndie.pulloverpro-rootless_3.0.2~rc2_iphoneos-arm64.deb), SHA256 `59bf2fc4426c4ed78b28654af622574fc385d50c219d61d96998f9e3582fd5e4`. Revenirea este un downgrade manual; RC2 ignoră noua cheie de poziții. Dacă SpringBoard se blochează: reboot, Dopamine fără tweak injection, apoi elimină/downgradează doar acest pachet. Nicio instalare, respring, terminare de proces, ștergere de date personale sau modificare a altor tweak-uri nu a fost executată automat.
