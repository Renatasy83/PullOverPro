# 0.5.10~panel.launch1 — Safari din panoul PPO

## Baza confirmată pe telefon

Utilizatorul a testat ppo-open 0.5.9 din NewTerm ca mobile:
- +defaultWorkspace: @16@0:8
- -openApplicationWithBundleID:: B24@0:8@16
- ABI supported: yes
- Launch request accepted: yes
- Safari s-a deschis efectiv, confirmat vizual.

0.5.8 a fost confirmată pentru lista reală, selecție persistentă, paginare, lock/unlock și absența PPO pe ecranul blocat. Această etapă adaugă butonul din SpringBoard; succesul din NewTerm nu dovedește că spawn-ul din SpringBoard are aceleași condiții.

Dezvoltare pe debug/panel-launch. main, beta-development și ramurile deja testate rămân intacte. Utilitarele ppo-open (0.5.9) și ppo-apps (0.5.7), inclusiv verificările ABI și limita Safari, sunt nemodificate. Licența GPL-3.0 și atribuirea originală se păstrează.

## Ce se schimbă

În panou apare „Deschide Safari”. Este dezactivat până când Safari este selectat și selecția este salvată sau recitită din fișier la deschiderea listei. Atingerea unei aplicații din listă continuă să facă doar selecția. La pornire, lista și selecția nu se citesc automat.

La apăsarea explicită:
1. Cererea unică este programată pe un worker; butonul este dezactivat în timpul cererii.
2. PPORunHelper refuză execuția pe main thread. Pornește prin posix_spawn numai /var/jb/usr/bin/ppo-open, cu argumentul fix --launch, fără shell sau argumente provenite din lista aplicațiilor.
3. Copilul are PATH și locale explicite. Nu primește mediul complet SpringBoard, variabilele de injecție sau descriptorii deschiși ai acestuia. Intrarea/ieșirea standard se redirecționează doar pentru copil către /dev/null. Identitatea procesului nu este schimbată și nu sunt adăugate entitlement-uri.
4. Utilitarul verifică din nou ABI-ul și selecția Safari, apoi solicită lansarea normală. SpringBoard nu invocă direct API-ul privat LaunchServices.
5. Așteptarea folosește waitpid WNOHANG și timp monoton pe worker, maximum 25 secunde. Utilitarul păstrează propriul alarm de 20 secunde. Nu se schimbă handlerul SIGCHLD al SpringBoard și nu se trimit semnale din părinte către PID-ul copilului.
6. La revenire se afișează rezultatul. „Safari: cerere acceptată” înseamnă exit 0 al utilitarului, nu dovadă vizuală a deschiderii.
7. Dacă așteptarea expiră, apare o eroare de wait, un semnal sau un ABI refuzat, testul este oprit până la respring, fără relansări automate. O cerere pornită înaintea schimbării selecției rămâne limitată la Safari.

Sandbox-ul, identitatea și alte condiții ale apelantului pot produce rezultate diferite față de NewTerm. Eroarea spawn este afișată separat de exit code. Un ECHILD poate însemna că rezultatul nu mai poate fi colectat de acest apelant; nu dovedește că Safari nu s-a deschis. Nu se modifică alte tweak-uri pentru a ocoli aceste rezultate.

## Test de pe telefon după CI verde

Păstrează .deb-ul funcțional 0.5.9 pentru revenire. Instalează manual numai 0.5.10~panel.launch1, ca actualizare a aceluiași pachet, și fă respring. Flag-urile PPO existente se păstrează.

1. Verifică întâi lista, scroll-ul, paginarea, tema și recentrarea.
2. Selectează Safari și așteaptă „Selectat: Safari”. Butonul „Deschide Safari” trebuie să fie activ. După respring, deschide lista și revino pentru recitirea selecției salvate.
3. Apasă o singură dată „Deschide Safari”, cu telefonul deblocat. Verifică vizual dacă Safari se deschide.
4. Revino în PPO și trimite mesajul rezultat, inclusiv orice cod numeric. Verifică și că mânerul și panoul rămân responsive.
5. Selectează altă aplicație: butonul de lansare trebuie să se dezactiveze. Nu se lansează alte aplicații în această etapă.
6. Verifică lock/unlock și absența PPO pe ecranul blocat.
7. Dacă apare o eroare, nu apăsa repetat. Fotografiază mesajul. Dacă Safari se deschide dar mesajul indică rezultat necunoscut, raportează ambele observații.

Lipsa unei lansări din panou nu justifică modificarea privilegiilor sau a sandbox-ului. Comanda manuală 0.5.9 rămâne disponibilă pentru comparație numai dacă este necesar; nu există apeluri automate la pornire.

Recuperare: dacă terminalul răspunde, touch /var/mobile/.ppo_disable și respring manual. Dacă telefonul rămâne blocat, repornire forțată, Dopamine cu injection oprit și dezinstalare exclusiv PPO Diagnostic. Nu șterge date personale și nu modifica alte tweak-uri.

## Verificări CI

Se păstrează analiza Clang și testele versiunilor precedente. Se adaugă analiza procesului și teste native pentru:
- refuzul execuției pe main thread;
- execuție din worker și mediu limitat;
- cod de ieșire nenul și executabil lipsă;
- limite de timp și colectarea ulterioară a copilului-fixture fără semnale.

CI verifică ambele arhitecturi pentru dylib și utilitare, payload rootless, dependențe, UUID-uri și SHA256. Nu execută SpringBoard și nu validează lansarea din sandbox-ul telefonului. Un build verde nu garantează comportamentul la rulare.

Compilare locală opțională în NewTerm ca mobile, într-un director nou:
```sh
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
git clone --branch debug/panel-launch https://github.com/Renatasy83/PullOverPro.git /var/mobile/PullOverPro-panel-launch
cd /var/mobile/PullOverPro-panel-launch
export THEOS=/var/jb/var/mobile/theos
sh scripts/build-local.sh
```

După confirmarea lansării Safari din panou urmează extinderea separată la alte aplicații verificate. Hosting-ul nu este activat în această versiune.
