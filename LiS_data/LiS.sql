/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
* 
*        Copyright 2018 Marco De Nicolo
*/

CREATE SCHEMA space;
SET SCHEMA 'space';

CREATE DOMAIN BONUS AS INTEGER
    DEFAULT 0
    NOT NULL
    CHECK(VALUE BETWEEN -6 AND 6);

CREATE DOMAIN STATS AS INTEGER
    DEFAULT 3
    NOT NULL
    CHECK(VALUE BETWEEN 3 AND 18);

CREATE TABLE dadi_init (
    id_eroe INTEGER NOT NULL REFERENCES eroi(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    d1 STATS,
    d2 STATS,
    d3 STATS,
    d4 STATS,
    d5 STATS,
    PRIMARY KEY(id_eroe)
);
CREATE TABLE utenti (
    id SERIAL PRIMARY KEY,
    mail TEXT UNIQUE NOT NULL CHECK(mail LIKE '_%@_%._%'),
    nome TEXT UNIQUE NOT NULL CHECK(nome NOT LIKE '%@%'),
    password TEXT NOT NULL
);
CREATE TABLE oggetti (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    descrizione TEXT,
    att BONUS,
    dif BONUS,
    pf BONUS,
    per BONUS,
    danno INTEGER NOT NULL CHECK(danno>=0),
    tipo SMALLINT NOT NULL DEFAULT 0 CHECK(tipo BETWEEN 0 AND 3) /*tipo: 0:valido solo in stanza, 1: valido sempre (cibo), 2:attacco, 3:difesa*/
);
CREATE TABLE nemici (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    descrizione TEXT
);
CREATE TABLE stanze (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    descrizione TEXT
);
CREATE TABLE collegamenti (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    descrizione TEXT
);
CREATE TABLE eroi (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    descrizione TEXT,
    forz STATS,
    inte STATS,
    cost STATS,
    agil STATS,
    general_pe INTEGER DEFAULT 0 NOT NULL,
    att INTEGER DEFAULT 0 NOT NULL,
    dif INTEGER DEFAULT 0 NOT NULL,
    per INTEGER DEFAULT 0 NOT NULL,
    pf INTEGER DEFAULT 0 NOT NULL,
    pf_scudo INTEGER DEFAULT 0 NOT NULL CHECK(pf_scudo>=0),
    pe INTEGER DEFAULT 0 NOT NULL,
    id_sstanza INTEGER REFERENCES stato_stanze(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    id_utente INTEGER NOT NULL REFERENCES utenti(id)
    ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE TABLE dungeons (
    id SERIAL PRIMARY KEY,
    --start_time TIMESTAMP,
    --incipit TEXT NOT NULL,
    finale INTEGER DEFAULT NULL REFERENCES stato_stanze(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE TABLE stato_stanze (
    id SERIAL PRIMARY KEY,
    visitata BOOLEAN NOT NULL DEFAULT FALSE,
    id_stanza INTEGER NOT NULL REFERENCES stanze(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    id_dungeon INTEGER NOT NULL REFERENCES dungeons(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT stanza_unica UNIQUE(id_stanza, id_dungeon)
);
CREATE TABLE stato_collegamenti (
    id SERIAL PRIMARY KEY,
    id_from_ss INTEGER NOT NULL REFERENCES stato_stanze(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    id_to_ss INTEGER NOT NULL REFERENCES stato_stanze(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    id_collegamento INTEGER NOT NULL REFERENCES collegamenti(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    visibile BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE zaini (
    id SERIAL PRIMARY KEY,
    id_eroe INTEGER NOT NULL REFERENCES eroi(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    id_oggetto INTEGER NOT NULL REFERENCES oggetti(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    is_equip BOOLEAN NOT NULL DEFAULT FALSE --con TRUE può essere usato su uno di attacco,uno difesa e N consumabili
);
CREATE TABLE stato_oggetti (
    id SERIAL PRIMARY KEY,
    id_oggetto INTEGER NOT NULL REFERENCES oggetti(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    id_sstanza INTEGER NOT NULL REFERENCES stato_stanze(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    visibile BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE stato_nemici (
    id SERIAL PRIMARY KEY,
    att INTEGER DEFAULT 0 NOT NULL,
    dif INTEGER DEFAULT 0 NOT NULL,
    pf INTEGER DEFAULT 0 NOT NULL,
    danno INTEGER NOT NULL CHECK(danno>0),
    id_nemico INTEGER NOT NULL REFERENCES nemici(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    id_sstanza INTEGER NOT NULL REFERENCES stato_stanze(id)
    ON UPDATE CASCADE ON DELETE CASCADE
);
