# 0.5.11~spawn.diag1 — diagnostic al refuzului de pornire

## Dovezi de pe telefon

Cu pachetul 0.5.10 instalat, utilizatorul a confirmat din nou:
- /var/jb/usr/bin/ppo-open --launch din NewTerm deschide Safari.
- Butonul PPO afișează „Pornire utilitar: eroare 1”.
- SpringBoard și interfața rămân responsive.

Codul 1 este EPERM. Mesajul este produs pe calea de pornire, înainte de colectarea unui exit code al utilitarului. În 0.5.10 nu era înregistrat care apel din configurarea/pornirea copilului a eșuat. Nu atribuim încă refuzul unui sandbox, semnării, Dopamine sau ElleKit. Lipsesc încă logurile sistemului pentru o atribuire definitivă. Această problemă nu confirmă cauza vechilor watchdog-uri.

## Schimbarea

Aceleași apeluri de lansare ca în 0.5.10: același helper și argv --launch, aceleași flag-uri, același mediu explicit, aceeași redirecționare, aceiași timpi. Nu se fac schimbări de privilegii sau entitlement-uri. Nu se introduc apeluri private noi.

PPOLaunchResult include acum etapa exactă (main-thread, arguments, clock, actions-init, attributes-init, set-flags, stdin-action, stdout-action, stderr-action, posix_spawn, waitpid, child-exit, child-signal sau deadline), UID/EUID ale apelantului și rezultatele publice stat/access(X_OK) asupra executabilului. Preflight-ul doar măsoară; nu decide dacă se încearcă lansarea.

După o apăsare explicită, workerul salvează atomic:
    /var/mobile/Library/Logs/PullOverPro/spawn-0.5.11.json

Raportul conține versiunea OS, etapa, codurile de eroare, UID/EUID și owner/mod/acces pentru singurul executabil PPO. Nu conține mediul procesului, credențiale sau inventarul aplicațiilor. Înlocuiește doar raportul propriu al acestei versiuni. UI arată etapa alături de cod, de exemplu „posix_spawn: eroare 1”.

Uid-ul proprietarului executabilului și UID/EUID ale SpringBoard sunt câmpuri separate; proprietarul root al unui fișier nu dovedește că SpringBoard rulează ca root. Chiar și un rezultat stat/access reușit nu dovedește că execuția este permisă.

Aceasta este o etapă de diagnostic, nu o soluție declarată. main, beta-development și ramurile anterioare sunt păstrate. Ramură nouă: debug/spawn-diagnostic. GPL-3.0 și atribuirea originală rămân intacte.

## Test manual după CI verde

Păstrează .deb-ul 0.5.10 pentru revenire. Instalează manual .deb-ul 0.5.11~spawn.diag1, ca actualizare a aceluiași pachet, și fă respring. Păstrează flag-urile PPO.

1. Selectează Safari în panou și așteaptă confirmarea salvării.
2. Apasă o singură dată „Deschide Safari”.
3. Trimite mesajul exact afișat și fișierul spawn-0.5.11.json, deschis din Filza la calea de mai sus.
4. Alternativ, afișează raportul în NewTerm:
   cat /var/mobile/Library/Logs/PullOverPro/spawn-0.5.11.json
5. Dacă raportul nu există, trimite mesajul/captura; nu schimba permisiuni sau proprietari de fișiere.

Nu sunt necesare modificări ale altor tweak-uri, entitlement-uri, sandbox sau setări Dopamine. Nu repeta lansarea în buclă.

Recuperare: dacă terminalul răspunde, touch /var/mobile/.ppo_disable și respring manual. Pentru blocaj, procedura verificată: repornire forțată, Dopamine cu injection oprit și dezinstalarea exclusivă a PPO Diagnostic. Nu șterge date personale.

## Verificări

CI păstrează analiza Clang, testele ABI și ale datelor, testele procesului și validarea rootless. Testele procesului verifică suplimentar etapele, identitatea și preflight-ul atât la succes, cât și pentru executabil lipsă. Nu reproduc politica de execuție a SpringBoard de pe telefon.

Compilare locală opțională în NewTerm ca mobile, într-un director nou:
```sh
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
git clone --branch debug/spawn-diagnostic https://github.com/Renatasy83/PullOverPro.git /var/mobile/PullOverPro-spawn-diag
cd /var/mobile/PullOverPro-spawn-diag
export THEOS=/var/jb/var/mobile/theos
sh scripts/build-local.sh
```
