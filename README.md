# Fiksařka

Jméno todo

Tohle repo obsahuje všechny texty a obrázky k fiksí kuchařce.

## Local build

Pro lokální build stačí spusit `./build.sh`, pozor, potřebujete mít vedle této složky
ještě fiks-html a fiks-pdf, Woowoo templatu, kterou kuchařka používá. A také přístup k docker imagi s Woowoo.


Pokud chceš build pouze html/pdf spusť pouze `./build-html.sh` respektive `./build-pdf.sh` na ně stačí mít pouze jednu z template.


Templaty jsou repozitáře na Githubu pod *fiks-org*. Na přístup k docker imagi získáš přes Github secrets tohoto
repa. Přihlásíš se do container registry pomocí
```bash
echo "${CI_REGISTRY_PASSWORD}" | docker login gitlab.fit.cvut.cz:5050 -u woowoo --password-stdin
```
Kde `${CI_REGISTRY_PASSWORD}` nahradíš za obsah tohoto secretu. A pak už stačí spusit build script.


Výsledek najdeš v `./build/{fiks-html,fiks-pdf}`.


# Plánovaná struktura
* Úvod do algoritmů
* Intro do složitosti
* Ukázka výpočtu složitosti na vyhledávacích a řadících algoritmech
* Grafy
* Nejkratší cesta, kostra, a další grafový algoritmy
* Datový struktury (array, queue, stack, vyhledávací stromy, binární halda, hashtables, seg tree)
* Teorie čísel
* DP
* Geometrie
