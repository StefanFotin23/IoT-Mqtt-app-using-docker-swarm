Tema 3 SPRC 2023/2024 - Fotin Andrei-Stefan 343C3


RULARE

run --build ==> make all

stop ==> make stop
start ==> make start

Dupa pornire, intram in browser la adresa:
localhost:1880 pentru a putea accesa interfata Node-Red
(Pentru vizualizare mai facila a executiei programului,
debugging mai verbose si posibilitatea de flow control,
adica am implementat diverse features integrate pentru
a simula input JSON de la senzori (random), a popula
baza de date cu 1000 intrari random de la cele 2 statii
(senzori), testarea serviciilor prin request-uri HTTP
si posibilitatea de a efectua orice modificari care pot
aparea pe parcurs (exemplu, dorim sa adaugam functionalitati
in plus, sa adaugam mai multe sabloane de date de la senzori,
sa imbunatatim modalitatea in care se genereaza datele
transmise de senzori (sa eliminam zgomotul si sa avem date
mai smooth si mai realiste, exemplu:
temperatura la timpul t = 20grade, la t + 1 secunda: 28 grade;
acest gen de valori pot aparea deoarece simulez valorile
random intre niste intervale, exemplu: random(a, b) si atribui
pentru fiecare metrica: temperatura = random(16, 37),
humid = random (35, 70) etc.


IMPLEMENTARE

In stack.yml al docker swarm definim serviciile, unde alegem sa folosim
(dupa cum spune cerinta) InfluxDB, Grafana, Mosquitto ca MQTT Broker si apoi
in cerinta se specifica necesitatea unui adapter care primeste mesaje MQTT si 
insereaza datele dupa prelucrare in DB.
Eu am ales sa simulez total si componenta care trimite mesajele MQTT extern
printr-un serviciu python (similar cu cel din lab5) care expune 2 endpoint-uri:
- unul pentru verificarea statusului containerului: Ping, care intoarce practic 
200 OK daca s-a realizat requestul normal si un status code negativ in cazul in
care serverul e down (astfel ne este mai usor sa facem debugging si sa ne dam
seama in arhitectura cu micro-servicii care dintre acestea este problematic)
- celalalt endpoint care este practic singurul important in flow-ul nostru,
este acela care primeste mesaje HTTP printr-un GET Request cu 2 parametrii:
message si topic. Acestea le voi folosi pentru a trimite la Brokerul MQTT
mesajul la topicul specificat in mod automat.
Astfel clientul MQTT ruleaza in background si este usor de apelat prin aceste
request-uri HTTP, astfel incat putem sa configuram real-time, fara nevoie de 
redeployment sau alte modificari de cod, ce mesaje va trimite acesta la Broker.

Am ales sa adaug acest serviciu pentru a putea simula in mod cat mai real senzorii,
iar acesta poate simula practic un numar infinit de senzori (daca am avea prea multi
senzori de simulat si astfel probleme de scalabilitate, foarte multe mesaje in acelasi timp,
putem adauga un serviciu coada de mesaje gen ActiveMQ / RabbitMQ sau Kafka etc. pentru a stoca
mesajele si brokerul sa le preia direct de acolo, practic eliminand necesitatea folosirii acestui
endpoint, desi acesta ar putea ramane ca feature pentru ca totusi prezinta flexibilitate pentru 
necesitatile noastre).

Acesta a fost serviciul auxiliar implementat de mine care ajuta la testare, simulare a flowului
stackului nostru si este util deoarece am ales sa implementez un adapter cu Node-Red, 
din aceeasi cauza, a flexibilitatii. Consider ca, infara faptului ca acest tool reprezinta
standardul pe piata IoT pentru acest gen de aplicatii, ofera si capacitatea de modificari
real-time, nu necesita compilari, redeployment al stackului etc. pentru modificari.
Totodata am ascuns toate serviciile care nu erau necesare sa fie vizibilie catre host (PC-ul local)
exact cum s-a specificat in cerinta, clientul meu MQTT care ruleaza ca server in background este total
ascuns pe local, in schimb am considerat ca marele avantaj al folosirii Node-Red, asa cum am
expus si mai sus, ar fi ca acesta sa poata fi folosit pe local real-time acesta fiind efectiv
"panoul de control" al aplicatiei noastre, astfel incat am expus portul de la container pe local.

Am ales sa folosesc Node-Red pentru adapter deoarece este alegerea unica si principala in domeniu 
pentru aceste aplicatii si deoarece permite mai facil implementarea conceptului CI/CD. Practic putem modifica
orice, rapid, oricand, fara ca serviciul sa fie down, acesta ramane up mereu, doar ii schimbam 
efectiv codul care ruleaza pe server (adica ce trebuie el sa faca efectiv)

Pentru toate serviciile am creat Dockerfiles separate pentru un timp mai scazut la initilizarea
containerului, in detrimentul procesului de build (care este realizat doar la build, adica o data)

Pentru grafana, am conceput un script bash care este rulat in container, trimite requesturi catre sine
si acolo prin acele POST requests cu body potrivit, trimit datele de configurare necesare:
adica configurarea conexiunii cu InfluxDB si efectiv crearea celor 2 dashboards.
Acest script se ruleaza de fiecare data cand se porneste containerul, si nu este nociv in cazul
in care aceste setup-uri au fost deja facute (exista deja conexiunea sau dashboardurile), doar
intoarce raspuns la requesturi care specifica ca aceastea deja exista (se pot vedea in logs)

Totodata am ales sa folosesc un fisier Makefile, in loc de script-uri sh, pentru ca iarasi, 
prezinta mai multa flexibilitate, ofera mai multe beneficii si usurinta la rulare
(nu mai stau sa scriu eu o suita de comenzi docker swarm, sunt toate acolo)
Am agregat pentru fiecare "serviciu" gen make all, make start, make stop,
toate celelalte "subservicii" care sunt efectiv definite prin comenzile necesare:
Adica "make all: stop wait build start" executa aceste comenzi astfel incat flow-ul sa fie cat mai
simplu, sa evite erori si sa fie user-friendly. Am adaugat la make start optiunea de a astepta
pana cand toate serviciile ruleaza healthy si apoi afiseaza un make status, ca sa vedem lucrurile acestea,
astfel incat utilizatorul stie ca de abia atunci poate intra efectiv sa faca ce doreste, in Node-Red / Grafana,
de exemplu.
Totodata aici am integrat si rularea buildurilor de imagini docker, in make build.

In general am folosit cateva smecherii pentru a verifica intern starea de healthy a containerelor,
pentru ca aceasta era necesara in interactiunea dintre ele.
Exemplu, in scriptul init.sh pt Grafana, mai intai astept ca InfluxDB sa fie healthy, folosind 
intr-un loop infinit: trimiterea de requesturi la serviciul InfluxDB/healthy, pana cand acesta intoarce status OK 200.
Am tot folosit genul asta de smecherii mici cand am intampinat probleme.