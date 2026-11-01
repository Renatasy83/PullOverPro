# PullOver Pro 1.0.0 RC1

Candidat apropiat de interfața originală: sertar lateral stânga/dreapta, ferestre persistente implicit, comutator Recente/Favorite, tragere către ținta centrală pentru lansare normală și preferințe/favorite în Configurări.

Acest DEB a fost compilat și inspectat automat. Noua interfață și integrarea pe telefon încă necesită proba reală combinată; funcționarea tuturor aplicațiilor și compatibilitatea generală Dopamine/ElleKit nu sunt confirmate.

- Sursa executabilului: [f3653171e59fd04cb2ae0c7b70ba28acf4c20fef](https://github.com/Renatasy83/PullOverPro/tree/f3653171e59fd04cb2ae0c7b70ba28acf4c20fef).
- [GitHub Actions41337396599](https://github.com/Renatasy83/PullOverPro/actions/runs/41337396599), job124940003921; toate cele28 de suite automate au trecut.
- [Artifact13095304677](https://github.com/Renatasy83/PullOverPro/actions/runs/41337396599/artifacts/13095304677).
- SHA256 DEB: `344439230bc4edd2994cccfbf012d5e00f91a66af6cbb6426c951b04bc387cda`.
- SHA256 ZIP Actions: `605fe2f52d0ad6fa0ad8821d669c7dbd7c24b577a0e9a52e53ff6f4a873ceaf4`.
- [Raport complet, limite și proba pe dispozitiv](https://github.com/Renatasy83/PullOverPro/blob/debug/original-interface-rc/VALIDATION_1.0.0_RC1.md).
- VALIDATION.json păstrează raportul generat pentru acest executabil; nu transformă testele native în probe iOS.

Instalează manual printr-un manager care rezolvă dependențele, de exemplu Sileo. Pachetul necesită PreferenceLoader. Fă respring manual și redeschide Configurări. Verifică într-o singură probă preferințele, sertarul cu Safari/Fișiere, interacțiunea, închiderea X/redeschiderea și închiderea la blocare. Nu este necesar un test pentru fiecare aplicație. Trimite host-1.0.0.json dacă este nevoie de depanare.

Ferestrele sunt persistente implicit. Oprirea păstrării în Configurări selectează temporizarea de aproximativ15secunde pentru următoarea deschidere. X sau dezactivarea PPO în Configurări sunt primele căi de închidere. Pentru recuperare se poate crea /var/mobile/.ppo_disable și face respring manual; dacă injecția împiedică pornirea, pornește Dopamine fără tweak injection și elimină numai PPO. Nu șterge favoritele sau selecția.

## Revenire la ultimul build confirmat

[DEB0.17.0 păstrat permanent](https://raw.githubusercontent.com/Renatasy83/PullOverPro/a5c6ac9bcd6d188b9fb2b5d6032ff84cd0911920/recovery/0.17.0/com.renatasy83.pulloverpro.diagnostic_0.17.0~dev.namedconfigs1_iphoneos-arm64.deb)

SHA256: `0e2d6a5792167e29d3eec58f843b3fc121efb93b51c20a0bf70703c530010bda`. Sursa confirmată este ad6ece8c6cbde196cc4be1ee0b2910cd9c832134. Arhiva de recuperare nu depinde de expirarea Actions.

Original: [c1d3r / Will Smillie](https://github.com/c1d3rdev/PullOver-Pro), GPL-3.0. [Licența completă](../../LICENSE) și sursele/scripturile corespunzătoare rămân în acest repository. Main, celelalte tweak-uri și datele personale nu sunt modificate de această arhivare. Nicio instalare sau respring nu este executată automat.
