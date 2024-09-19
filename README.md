# Fiksařka

Jméno todo

Tohle repo obsahuje všechny texty a obrázky k fiksí kuchařce.

## Local build

Pro lokální build stačí spusit `./build.sh`, pozor, potřebujete mít vedle této složky
ještě fiks-html a fiks-pdf, to jsou Woowoo templaty, které kuchařka používá. A také přístup k docker imagi s Woowoo.


Pokud chceš build pouze html/pdf spusť pouze `./build-html.sh` respektive `./build-pdf.sh` na ně stačí mít pouze jednu z template.


Templaty jsou repozitáře na Githubu pod *fiks-org*. Na přístup k docker imagi získáš přes DM @bertik23.
Pak se přihlásíš se do container registry pomocí
```bash
docker login gitlab.fit.cvut.cz:5050 -u woowoo --password-stdin
```
a zadáním hesla co dostaneš
Pak už stačí spusit build script.


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
