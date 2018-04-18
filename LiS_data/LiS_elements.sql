/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
* 
*        Copyright 2018 Marco De Nicolo
*/

/*STANZE*/
INSERT INTO stanze(nome,descrizione) VALUES('CABINA DI PILOTAGGIO', 'Ci sono molte leve e bottoni, forse sarebbe meglio non toccare nulla...');
INSERT INTO stanze(nome,descrizione) VALUES('ALLOGGIO DEL CAPITANO', 'C''è un letto ancorato al pavimento. La stanza è molto spoglia.');
INSERT INTO stanze(nome,descrizione) VALUES('MENSA', 'Ci sono molti tavoli ancora apparecchiati e uno schermo con il piatto del giorno sul muro... la solita sbobba.');
INSERT INTO stanze(nome,descrizione) VALUES('SALA CENTRALE', 'Molto ampia, con un gigantesco albero al centro.');
INSERT INTO stanze(nome,descrizione) VALUES('SALA MACCHINE', 'C''è un gran baccano.');
INSERT INTO stanze(nome,descrizione) VALUES('SMALTIMENTO RIFIUTI', 'Ci sono molti pezzi di ferraglia arruginita che dovrebbero essere compattati e fusi per essere riciclati.');
INSERT INTO stanze(nome,descrizione) VALUES('IMPIANTO ENERGETICO', 'Sei sopra un ponte. Sotto di te, racchiusa da un guscio super avanzato, c''è una stella morente che fornisce energia all''intera astronave.');
INSERT INTO stanze(nome,descrizione) VALUES('TEATRO', 'Un teatro per allietare le serate dei passeggeri.');
INSERT INTO stanze(nome,descrizione) VALUES('SALA CINEMA', 'Cinema con un proiettore di ologrammi di ultima generazione.');
INSERT INTO stanze(nome,descrizione) VALUES('TERRAZZA PANORAMICA', 'Una terrazza coperta da una gigantesca cupola trasparente. Prenditi un momento per osservare le stelle.');
INSERT INTO stanze(nome,descrizione) VALUES('AREA RELAX', 'Ci sono molti divani che circondano una piscina. Ci sono diversi corpi senza vita a terra.');
INSERT INTO stanze(nome,descrizione) VALUES('AREA GIOCHI', 'Ci sono delle piccole stanze con giochi di realtà virtuale di ultima generazione. Alcuni sono ancora collegati agli apparecchi');
INSERT INTO stanze(nome,descrizione) VALUES('PARCO ARTIFICIALE', 'Un parco che contiene parte della flora e fauna terrestre.');
INSERT INTO stanze(nome,descrizione) VALUES('BAGNO', 'Sembrerebbe esserci una perdita di acqua. L''acqua è molto preziosa, viene riciclata o raccolta dalle comete di passaggio. Quando finisci ricordati di ripararlo.');

/*COLLEGAMENTI*/
INSERT INTO collegamenti(nome,descrizione) VALUES('PORTA A SCORRIMENTO VERTICALE', 'Una classica porta tecnologicamente avanzata di colore grigio.');
INSERT INTO collegamenti(nome,descrizione) VALUES('CORRIDOIO', 'Muri imbrattati di sangue... non deve essere un buon auspicio.');
INSERT INTO collegamenti(nome,descrizione) VALUES('CORRIDOIO', 'Non vedo alieni/mostri/nemici vari in quella direzione (forse).');
INSERT INTO collegamenti(nome,descrizione) VALUES('CORRIDOIO STRETTO', 'Questo corridoio è così stretto che a fatica riuscirai a superarlo.');
INSERT INTO collegamenti(nome,descrizione) VALUES('VARCO OSCURO', 'Non si riesce a vedere nulla, si sente solo un forte odore di putrefazione.');

/*OGGETTI*/
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('SPADA LASER', 'Apparteneva ad uno jedi passato al lato oscuro.', 6, 0, 0, 4, 5, 2);
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('PIEDE DI PORCO', 'Arma base di qualunque gioco che si rispetti.', 2, 1, 0, 0, 4, 2);
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('CIBO IN SCATOLA','Sembrano fagioli, ma non ne sono certo.', 0, 0, 2, 0, 0, 1);
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('SCUDO DI ENERGIA','Un potentissimo scudo che crea una barriera di energia.', 0, 6, 0, -1, 0, 3);
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('ALIENADE PICCOLO','Integratore alimentare alieno da 50cl.', 2, 2, 3, -1, 0, 0);
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('ALIENADE GRANDE','Integratore alimentare alieno da 100cl.', 4, 4, 5, -2, 0, 0);
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('FUCILE AD IMPULSI', 'Classico fucile delle colonie marziane.', 4, 0, 0, 0, 5, 2);
INSERT INTO oggetti(nome,descrizione,att,dif,pf,per,danno,tipo) VALUES('PANNELLO FOTOVOLTAICO','Può essere usato come scudo.', 0, 4, 0, 0, 0, 3);

/*NEMICI*/
INSERT INTO nemici(nome,descrizione) VALUES('ALIENO DALLA TESTA OVALE', 'Nero, dai denti aguzzi e testa allungata. Ricorda molto l''alieno di quel film famoso.');
INSERT INTO nemici(nome,descrizione) VALUES('VERME SPAZIALE', 'Tentarono di conquistare la Terra una volta.');
INSERT INTO nemici(nome,descrizione) VALUES('DALEK', 'Un robot apparentemente innocuo. Non sottovalutarli, sono la nemesi del Dottore.');
INSERT INTO nemici(nome,descrizione) VALUES('KREE', 'Una razza aliena dalla pelle blu, scientificamente e tecnologicamente avanzata.');
INSERT INTO nemici(nome,descrizione) VALUES('WOOKIEE', 'Un grosso umanoide guerriero, molto peloso. Può essere il migliore tra gli amici o il tuo peggiore incubo (purtroppo per te è la seconda).');
INSERT INTO nemici(nome,descrizione) VALUES('CYBORG', 'Un essere umano potenziato per sopravvivere in ambienti extraterrestri inospitali.');
INSERT INTO nemici(nome,descrizione) VALUES('ROMULANO', 'Specie umanoide che ha distrutto il pianeta Vulcano');
