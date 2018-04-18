/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

--
-- PostgreSQL database dump
--

-- Dumped from database version 10.1
-- Dumped by pg_dump version 10.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: space; Type: SCHEMA; Schema: -; Owner: utente
--

CREATE SCHEMA space;


ALTER SCHEMA space OWNER TO utente;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: plpython3u; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: utente
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plpython3u;


ALTER PROCEDURAL LANGUAGE plpython3u OWNER TO utente;

SET search_path = space, pg_catalog;

--
-- Name: bonus; Type: DOMAIN; Schema: space; Owner: utente
--

CREATE DOMAIN bonus AS integer DEFAULT 0 NOT NULL
	CONSTRAINT bonus_check CHECK (((VALUE >= '-6'::integer) AND (VALUE <= 6)));


ALTER DOMAIN bonus OWNER TO utente;

--
-- Name: stats; Type: DOMAIN; Schema: space; Owner: utente
--

CREATE DOMAIN stats AS integer DEFAULT 3 NOT NULL
	CONSTRAINT stats_check CHECK (((VALUE >= 3) AND (VALUE <= 18)));


ALTER DOMAIN stats OWNER TO utente;

--
-- Name: adia_stanza(integer); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION adia_stanza(sstanza integer) RETURNS TABLE(id_sstanza integer, visibile boolean, nome_stanza text, visitata boolean, nome_collegamento text, descrizione_collegamento text)
    LANGUAGE plpython3u
    AS $_$
rooms = []
plan = plpy.prepare("SELECT * FROM stato_collegamenti WHERE id_from_ss=$1 OR id_to_ss=$1",["integer"])
first_step = plpy.execute(plan,[sstanza])
for el in first_step:
    id_nsstanza = el["id_to_ss"] if el["id_from_ss"] == sstanza else el["id_from_ss"]
    plan2 = plpy.prepare("SELECT stanze.nome, stato_stanze.visitata FROM stanze JOIN stato_stanze ON stato_stanze.id_stanza = stanze.id WHERE stato_stanze.id=$1",["integer"])
    stanza = plpy.execute(plan2,[id_nsstanza])[0]
    plan2 = plpy.prepare("SELECT nome, descrizione FROM collegamenti WHERE id = $1",["integer"])
    col = plpy.execute(plan2,[el["id_collegamento"]])[0]
    rooms.append((id_nsstanza,el["visibile"],stanza["nome"],stanza["visitata"],col["nome"],col["descrizione"]))
return rooms
$_$;


ALTER FUNCTION space.adia_stanza(sstanza integer) OWNER TO utente;

--
-- Name: attacco(integer, integer); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION attacco(id_eroe integer, id_nemico integer) RETURNS void
    LANGUAGE plpython3u
    AS $_$
import random

#att-dif+1d20
def ok_attacco(att,dif):
    value = att-dif+random.randint(1,20)
    return True if value > 12 else False

plan = plpy.prepare("SELECT eroi.att,eroi.dif,eroi.pf,eroi.pf_scudo,eroi.pe,oggetti.danno FROM eroi JOIN zaini ON zaini.id_eroe=eroi.id JOIN oggetti ON zaini.id_oggetto=oggetti.id WHERE oggetti.tipo=2 AND zaini.is_equip=$1 AND eroi.id=$2",["boolean","integer"])
hero = plpy.execute(plan,[True,id_eroe])[0]
plan = plpy.prepare("SELECT att,dif,pf,danno,id_sstanza FROM stato_nemici WHERE id=$1",["integer"])
nem = plpy.execute(plan,[id_nemico])[0]

#attacco eroe->nemico
if ok_attacco(hero["att"],nem["dif"]) :
    pf_nem = nem["pf"]-hero["danno"]
    if pf_nem<=0 :
        #uccido il nemico e guadagno pe
        plan = plpy.prepare("DELETE FROM stato_nemici WHERE id=$1",["integer"])
        plpy.execute(plan,[id_nemico])
        hero["pe"] += nem["danno"]
        plan = plpy.prepare("UPDATE eroi SET pe=$1 WHERE id=$2 ",["integer","integer"])
        plpy.execute(plan,[hero["pe"],id_eroe])
    else:
        plan = plpy.prepare("UPDATE stato_nemici SET pf=$1 WHERE id=$2",["integer","integer"])
        plpy.execute(plan,[pf_nem,id_nemico])

#attacco nemici->eroe
plan = plpy.prepare("SELECT * from stato_nemici WHERE id_sstanza=$1",["integer"])
nemici = plpy.execute(plan,[nem["id_sstanza"]])
for nem in nemici:
    if ok_attacco(nem["att"],hero["dif"]) :
        if hero["pf_scudo"]>0 :
            #scalo pf_scudo
            hero["pf_scudo"] -= nem["danno"]
            if hero["pf_scudo"] < 0 :
                #tolgo la differenza da pf e azzero pf_scudo
                hero["pf"] += hero["pf_scudo"]
                hero["pf_scudo"] = 0
        else:
            hero["pf"] -= nem["danno"]
        plan = plpy.prepare("UPDATE eroi SET pf=$1, pf_scudo=$2 WHERE id=$3",["integer","integer","integer"])
        plpy.execute(plan,[hero["pf"],hero["pf_scudo"],id_eroe])
$_$;


ALTER FUNCTION space.attacco(id_eroe integer, id_nemico integer) OWNER TO utente;

--
-- Name: capienza_zaino(); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION capienza_zaino() RETURNS trigger
    LANGUAGE plpython3u
    AS $_$
from math import ceil
plan = plpy.prepare("SELECT cost FROM eroi WHERE id=$1",["integer"])
cost = plpy.execute(plan,[TD["new"]["id_eroe"]])[0]["cost"]
plan = plpy.prepare("SELECT COUNT(id_oggetto) AS peso FROM zaini WHERE id_eroe=$1",["integer"])
peso = plpy.execute(plan,[TD["new"]["id_eroe"]])[0]["peso"]
if(peso+1 > ceil(cost/2)):
    return "SKIP"
return "OK"
$_$;


ALTER FUNCTION space.capienza_zaino() OWNER TO utente;

--
-- Name: check_type(); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION check_type() RETURNS trigger
    LANGUAGE plpython3u
    AS $_$
plan = plpy.prepare("SELECT tipo FROM oggetti WHERE id=$1",["integer"])
type = plpy.execute(plan,[TD["new"]["id_oggetto"]])[0]["tipo"]
if(type == 2 or type == 3):
    plan = plpy.prepare("SELECT zaini.id,zaini.id_oggetto FROM zaini JOIN oggetti ON zaini.id_oggetto=oggetti.id WHERE zaini.is_equip = $1 AND zaini.id_eroe = $2  AND oggetti.tipo =$3 AND zaini.id<>$4",["boolean","integer","integer","integer"])
    zaino = plpy.execute(plan,[True, TD["new"]["id_eroe"],type,TD["new"]["id"]])
    for el in zaino:
        plan = plpy.prepare("UPDATE zaini SET is_equip=$1 WHERE id=$2",["boolean","integer"])
        plpy.execute(plan,[False,el["id"]])
        #tolgo il vecchio oggetto di attacco o difesa
        plan = plpy.prepare("SELECT * FROM equip_obj($1,$2,$3)",["integer","integer","boolean"])
        plpy.execute(plan,[TD["new"]["id_eroe"], el["id_oggetto"], False])
#aggiorno i valori di att , dif ...
plan = plpy.prepare("SELECT * FROM equip_obj($1,$2,$3)",["integer","integer","boolean"])
plpy.execute(plan,[TD["new"]["id_eroe"], TD["new"]["id_oggetto"], True])
if(type == 1):
    plan = plpy.prepare("DELETE FROM zaini WHERE id = $1",["integer"])
    plpy.execute(plan, [TD["new"]["id"]])
$_$;


ALTER FUNCTION space.check_type() OWNER TO utente;

--
-- Name: crea_dungeon(integer); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION crea_dungeon(id_eroe integer) RETURNS void
    LANGUAGE plpython3u
    AS $_$
import random
import math

class Tree:
    def __init__(self):
        self.data = None
        self.child = []

#funzione per cercare la stanza iniziale, prende un nodo del tree e ritorna un pair (nodo iniziale, profondità maggiore)
def find_start(node):
    if len(node.child) <= 0:
        return [node,1]
    tupla = [None, 0]
    for n in node.child:
        t = find_start(n)
        if t[1] > tupla[1]:
            tupla = t
    tupla[1]+=1
    return tupla

#creo dungeon
plpy.execute("INSERT INTO dungeons(finale) VALUES(NULL)")
id_dungeon = plpy.execute("SELECT last_value FROM dungeons_id_seq")[0]["last_value"]

oggetti = plpy.execute("SELECT id FROM oggetti")
collegamenti = plpy.execute("SELECT * FROM collegamenti")
stanze = plpy.execute("SELECT * FROM stanze")
stati_stanze = []
#creo le stanze
for sta in stanze:
    plan = plpy.prepare("INSERT INTO stato_stanze(id_stanza, id_dungeon) VALUES($1,$2)",["integer","integer"])
    plpy.execute(plan,[sta["id"], id_dungeon])
    ss = plpy.execute("SELECT last_value FROM stato_stanze_id_seq")[0]["last_value"]
    stati_stanze.append(ss)
    #inserisco gli oggetti nello stato_stanza, ogni stanza ha da 0 a 6 oggetti(visibili e non)
    plan = plpy.prepare("INSERT INTO stato_oggetti(id_oggetto, id_sstanza, visibile) VALUES($1,$2,$3)",["integer","integer","boolean"])
    ran = random.randint(0,6)
    for i in range(0,ran):
        obj = random.randint(0,len(oggetti)-1)
        vis = True
        if random.randint(0,1):
            vis = False
        plpy.execute(plan,[oggetti[obj]["id"], ss, vis])
stati_stanze_cp = list(stati_stanze)
stanze_prese = []
ind = len(stati_stanze)-1 #random.randint(0,len(stati_stanze)-1)
#sposto da stati_stanze a stanze_prese
root = Tree()
root.data = stati_stanze.pop(ind)
stanze_prese.append(root)
while(len(stati_stanze)>0):
    #a chi lo collego?
    ind = random.randint(0,len(stanze_prese)-1)
    val = stati_stanze.pop(-1)
    node = Tree()
    node.data = val
    stanze_prese[ind].child.append(node)
    stanze_prese.append(node)
    #creo il collegamento
    id_col = collegamenti[random.randint(0,len(collegamenti)-1)]['id']
    plan = plpy.prepare("INSERT INTO stato_collegamenti(id_from_ss, id_to_ss, id_collegamento) VALUES($1,$2,$3)",["integer","integer","integer"])
    plpy.execute(plan,[stanze_prese[ind].data,val,id_col])

#aggiungo collegamenti nascosti
num = random.randint(1,int(len(stanze_prese)/2))
for i in range(0,num):
    from_ss = stanze_prese[random.randint(0,len(stanze_prese)-1)].data
    to_ss = stanze_prese[random.randint(0,len(stanze_prese)-1)].data
    if from_ss != to_ss:
        id_col = collegamenti[random.randint(0,len(collegamenti)-1)]['id']
        plan = plpy.prepare("INSERT INTO stato_collegamenti(id_from_ss, id_to_ss, id_collegamento, visibile) VALUES($1,$2,$3,$4)",["integer","integer","integer","boolean"])
        plpy.execute(plan,[from_ss,to_ss,id_col,False])
    else:
        i-=1

#inserisco stanza iniziale
inizio = find_start(root)[0].data
plan = plpy.prepare("UPDATE eroi SET id_sstanza=$1 WHERE id=$2",["integer","integer"])
plpy.execute(plan,[inizio,id_eroe])
plan = plpy.prepare("UPDATE stato_stanze SET visitata=TRUE WHERE id=$1",["integer"])
plpy.execute(plan,[inizio])

#inserisco stanza finale
plan = plpy.prepare("UPDATE dungeons SET finale=$1 WHERE id=$2",["integer","integer"])
plpy.execute(plan,[root.data,id_dungeon])

#oggetti iniziali
plan = plpy.prepare("INSERT INTO zaini(id_eroe,id_oggetto,is_equip) VALUES($1,$2,$3)",["integer","integer","boolean"])
base = plpy.execute("SELECT id,tipo FROM oggetti WHERE nome='PIEDE DI PORCO' OR nome='CIBO IN SCATOLA'")
for obj in base:
    boolval = True if obj["tipo"] == 2 else False
    plpy.execute(plan,[id_eroe,obj["id"],boolval])

#aggiungo i nemici, da inizio a root.data le stanze hanno un numero crescente
rangeSs = len(stati_stanze_cp)-1
#0<pEasy<=1, ad 1 è più probabile che sia facile sconfiggere i nemici
pEasy = 0.3
maxBonusAtt = plpy.execute("SELECT MAX(att) AS m FROM oggetti")[0]["m"]
maxBonusDif = plpy.execute("SELECT MAX(dif) AS m FROM oggetti")[0]["m"]
maxBonusPf = plpy.execute("SELECT MAX(pf) AS m FROM oggetti")[0]["m"]
maxDanno = plpy.execute("SELECT MAX(danno) AS m FROM oggetti")[0]["m"]
#att = (for + agi)/2 + bonus, varia da 3 a 18+bonus, rangeAtt è il range dell'' attacco
rangeAtt = 18 + maxBonusAtt - 3
rangeDif = 18 + maxBonusDif - 3
rangePf = 18 + maxBonusPf - 3
rangeDanno = maxDanno - 1
#calcolo l''incremento per ogni stanza, sottraggo un valore per semplificare il dungeon
incAtt = rangeAtt/rangeSs - pEasy*(rangeAtt/rangeSs)
incDif = rangeDif/rangeSs - pEasy*(rangeDif/rangeSs)
incPf = rangePf/rangeSs - pEasy*(rangePf/rangeSs)
incDanno = rangeDanno/rangeSs - pEasy*(rangeDanno/rangeSs)
#inizializzo i valori delle stat
attVal = 3
difVal = 3
pfVal = 3
dannoVal = 1
nemici = plpy.execute("SELECT id FROM nemici")
for ss in stati_stanze_cp:
    if(ss != root.data):
        num_nem = random.randint(1,3)
        for i in range(0,num_nem):
            plan = plpy.prepare("INSERT INTO stato_nemici(att,dif,pf,danno,id_nemico,id_sstanza) VALUES($1,$2,$3,$4,$5,$6)",["integer","integer","integer","integer","integer","integer"])
            plpy.execute(plan,[int(round(attVal)),int(round(difVal)),int(round(pfVal/num_nem)),math.ceil(dannoVal/num_nem),nemici[random.randint(0,len(nemici)-1)]["id"],ss])
    attVal += incAtt
    difVal += incDif
    pfVal += incPf
    dannoVal += incDanno
$_$;


ALTER FUNCTION space.crea_dungeon(id_eroe integer) OWNER TO utente;

--
-- Name: crea_utente(text, text, text); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION crea_utente(nome text, mail text, upassword text) RETURNS void
    LANGUAGE plpython3u
    AS $_$
from Crypto.Protocol.KDF import PBKDF2
pas = PBKDF2(upassword,b'\x83)\x95\xf0\xc6P\\\x9f').hex()
plan = plpy.prepare("INSERT INTO utenti(nome,mail,password) VALUES($1,$2,$3)",["text","text","text"])
plpy.execute(plan,[nome,mail,pas])
$_$;


ALTER FUNCTION space.crea_utente(nome text, mail text, upassword text) OWNER TO utente;

--
-- Name: equip_obj(integer, integer, boolean); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION equip_obj(id_eroe integer, id_obj integer, add boolean) RETURNS void
    LANGUAGE plpython3u
    AS $_$
molt = 1 if add == True else -1
plan = plpy.prepare("SELECT att,dif,per,pf,tipo FROM oggetti WHERE id = $1",["integer"])
obj = plpy.execute(plan,[id_obj])[0]
plan = plpy.prepare("SELECT att,dif,per,pf,pf_scudo FROM eroi WHERE id=$1",["integer"])
val = plpy.execute(plan,[id_eroe])[0]
pf_val = val["pf"]+obj["pf"]*molt
if(obj["tipo"] == 0):
    pf_val = val["pf_scudo"]+obj["pf"]*molt
    if(pf_val < 0):
        pf_val = 0
    plan = plpy.prepare("UPDATE eroi SET att=$1, dif=$2, per=$3, pf_scudo=$4 WHERE id=$5",["integer","integer","integer","integer","integer"])
else:
    plan = plpy.prepare("UPDATE eroi SET att=$1, dif=$2, per=$3, pf=$4 WHERE id=$5",["integer","integer","integer","integer","integer"])
plpy.execute(plan,[val["att"]+obj["att"]*molt, val["dif"]+obj["dif"]*molt, val["per"]+obj["per"]*molt, pf_val, id_eroe])
$_$;


ALTER FUNCTION space.equip_obj(id_eroe integer, id_obj integer, add boolean) OWNER TO utente;

--
-- Name: fin_eroe(integer, text, text, text, text); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION fin_eroe(id_eroe integer, forz text, inte text, cost text, agil text) RETURNS void
    LANGUAGE plpython3u
    AS $_$
plan = plpy.prepare("SELECT d1,d2,d3,d4,d5 FROM dadi_init WHERE id_eroe=$1",["integer"])
ret = plpy.execute(plan,[id_eroe])
plan = plpy.prepare("UPDATE eroi SET forz=$1, inte=$2, cost=$3, agil=$4, pf=$3, att=round(($1+$4)/2.0), dif=round(($3+$4)/2.0), per=$2 WHERE id=$5",["integer","integer","integer","integer","integer"])
plpy.execute(plan,[ret[0][forz],ret[0][inte],ret[0][cost],ret[0][agil],id_eroe])
plan = plpy.prepare("DELETE FROM dadi_init WHERE id_eroe=$1",["integer"])
plpy.execute(plan,[id_eroe])
$_$;


ALTER FUNCTION space.fin_eroe(id_eroe integer, forz text, inte text, cost text, agil text) OWNER TO utente;

--
-- Name: ini_eroe(integer, text, text); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION ini_eroe(id_utente integer, nome text, descrizione text) RETURNS integer
    LANGUAGE plpython3u
    AS $_$
plan = plpy.prepare("INSERT INTO eroi(nome, descrizione, id_utente) VALUES($1,$2,$3)",["text","text","integer"])
plpy.execute(plan,[nome,descrizione,id_utente])
return plpy.execute("SELECT last_value FROM eroi_id_seq")[0]["last_value"]
$_$;


ALTER FUNCTION space.ini_eroe(id_utente integer, nome text, descrizione text) OWNER TO utente;

--
-- Name: lancio_dadi(integer); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION lancio_dadi(id_eroe integer) RETURNS void
    LANGUAGE plpython3u
    AS $_$
import random
#azzero vecchi valori
plan = plpy.prepare("DELETE FROM zaini WHERE id_eroe=$1",["integer"])
plpy.execute(plan,[id_eroe])
plan = plpy.prepare("UPDATE eroi SET forz = 3, inte = 3, cost = 3, agil = 3, att = 0, dif = 0, per = 0, pf = 0, pf_scudo = 0, pe = 0, id_sstanza = NULL WHERE id = $1",["integer"])
plpy.execute(plan,[id_eroe])
#lancio dadi
num = [id_eroe]
plan = plpy.prepare("DELETE FROM dadi_init WHERE id_eroe=$1",["integer"])
plpy.execute(plan,num)
for i in range(1,6):
    num.append(random.randint(3,18))
plan = plpy.prepare("INSERT INTO dadi_init VALUES($1,$2,$3,$4,$5,$6)",["integer","integer","integer","integer","integer","integer"])
plpy.execute(plan,num)
$_$;


ALTER FUNCTION space.lancio_dadi(id_eroe integer) OWNER TO utente;

--
-- Name: login_utente(text, text); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION login_utente(nomemail text, upassword text) RETURNS boolean
    LANGUAGE plpython3u
    AS $_$
from plpy import spiexceptions
from Crypto.Protocol.KDF import PBKDF2
pas = PBKDF2(upassword,b'\x83)\x95\xf0\xc6P\\\x9f').hex()
try:
    plan = plpy.prepare("SELECT password FROM utenti WHERE nome=$1 OR mail=$1",["text"])
    hashpas = plpy.execute(plan,[nomemail])
except plpy.SPIError:
    return False
else:
    if hashpas.nrows() > 0 and hashpas[0]["password"] == pas:
        return True
    return False
$_$;


ALTER FUNCTION space.login_utente(nomemail text, upassword text) OWNER TO utente;

--
-- Name: pf_control(); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION pf_control() RETURNS trigger
    LANGUAGE plpython3u
    AS $_$
plan = plpy.prepare("DELETE FROM dungeons WHERE id = (SELECT id_dungeon FROM stato_stanze WHERE id =$1)",["integer"])
plpy.execute(plan,[TD["new"]["id_sstanza"]])
plan = plpy.prepare("SELECT * FROM lancio_dadi($1)",["integer"])
plpy.execute(plan,[TD["new"]["id"]])
$_$;


ALTER FUNCTION space.pf_control() OWNER TO utente;

--
-- Name: reset_e_attacco(); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION reset_e_attacco() RETURNS trigger
    LANGUAGE plpython3u
    AS $_$
import random
#setto come visitata la stanza
plan = plpy.prepare("UPDATE stato_stanze SET visitata=$1 WHERE id=$2",["boolean","integer"])
plpy.execute(plan,[True,TD["new"]["id_sstanza"]])

#è la finale?
plan = plpy.prepare("SELECT * FROM dungeons WHERE id=(SELECT id_dungeon FROM stato_stanze WHERE id=$1)", ["integer"])
dun = plpy.execute(plan,[TD["new"]["id_sstanza"]])[0]
if TD["new"]["id_sstanza"] == dun["finale"] :
    plan = plpy.prepare("SELECT COUNT(id) AS num FROM stato_stanze WHERE id_dungeon=$1 AND visitata=$2",["integer","boolean"])
    visrooms = plpy.execute(plan,[dun["id"],True])[0]["num"]
    plan = plpy.prepare("UPDATE eroi SET general_pe=$1 WHERE id=$2", ["integer","integer"])
    plpy.execute(plan,[TD["new"]["general_pe"]+TD["new"]["pe"]+visrooms*10,TD["new"]["id"]])
    plan = plpy.prepare("SELECT * FROM lancio_dadi($1)",["integer"])
    plpy.execute(plan,[TD["new"]["id"]])
    plan = plpy.prepare("DELETE FROM dungeons WHERE id = $1",["integer"])
    plpy.execute(plan,[dun["id"]])
    return "OK"

#tolgo da zaino gli oggetti usati nella stanza precedente e azzero i pf_scudo in equip_obj
oggetti = plpy.execute("SELECT zaini.id,zaini.id_oggetto FROM zaini JOIN oggetti ON zaini.id_oggetto=oggetti.id WHERE zaini.is_equip = 't' AND oggetti.tipo = 0")
for obj in oggetti:
    plan = plpy.prepare("SELECT * FROM equip_obj($1,$2,$3)",["integer","integer","boolean"])
    plpy.execute(plan,[TD["new"]["id"],obj["id_oggetto"],False])
    plan = plpy.prepare("DELETE FROM zaini WHERE id=$1",["integer"])
    plpy.execute(plan,[obj["id"]])

#i nemici attaccano in automatico
plan = plpy.prepare("SELECT att,dif,pf,danno FROM stato_nemici WHERE id_sstanza=$1",["integer"])
nemici = plpy.execute(plan,[TD["new"]["id_sstanza"]])
for nem in nemici:
    d1_20 = random.randint(1,20)
    value = nem["att"]-TD["new"]["dif"] + d1_20
    if value > 12 :
        plan = plpy.prepare("UPDATE eroi SET pf=$1 WHERE id=$2",["integer","integer"])
        plpy.execute(plan,[TD["new"]["pf"]-nem["danno"],TD["new"]["id"]])
$_$;


ALTER FUNCTION space.reset_e_attacco() OWNER TO utente;

--
-- Name: segreti(integer); Type: FUNCTION; Schema: space; Owner: utente
--

CREATE FUNCTION segreti(id_eroe integer) RETURNS void
    LANGUAGE plpython3u
    AS $_$
import random
plan = plpy.prepare("SELECT pf, pf_scudo, per, id_sstanza FROM eroi WHERE id=$1",["integer"])
hero = plpy.execute(plan,[id_eroe])[0]
#tolgo 1 pf, prima vedo se posso toglierlo da pf_scudo
if hero["pf_scudo"] > 0:
    hero["pf_scudo"] -= 1
else:
    hero["pf"] -= 1
plan = plpy.prepare("UPDATE eroi SET pf=$1, pf_scudo=$2 WHERE id=$3",["integer","integer","integer"])
plpy.execute(plan,[hero["pf"],hero["pf_scudo"],id_eroe])
if random.randint(1,20) < hero["per"] :
    plan = plpy.prepare("SELECT id FROM stato_oggetti WHERE id_sstanza=$1 AND visibile=$2",["integer","boolean"])
    elem_obj = plpy.execute(plan,[hero["id_sstanza"],False])
    plan = plpy.prepare("SELECT id FROM stato_collegamenti WHERE (id_from_ss=$1 OR id_to_ss=$1) AND visibile=$2",["integer","boolean"])
    elem_col = plpy.execute(plan,[hero["id_sstanza"],False])
    #scelgo a caso ma controllo che non sia vuoto
    if random.randint(0,1) and elem_obj:
        plan = plpy.prepare("UPDATE stato_oggetti SET visibile=$1 WHERE id=$2",["boolean","integer"])
        plpy.execute(plan,[True,elem_obj[random.randint(0,len(elem_obj)-1)]["id"]])
    elif elem_col:
        plan = plpy.prepare("UPDATE stato_collegamenti SET visibile=$1 WHERE id=$2",["boolean","integer"])
        plpy.execute(plan,[True,elem_col[random.randint(0,len(elem_col)-1)]["id"]])
$_$;


ALTER FUNCTION space.segreti(id_eroe integer) OWNER TO utente;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: collegamenti; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE collegamenti (
    id integer NOT NULL,
    nome text NOT NULL,
    descrizione text
);


ALTER TABLE collegamenti OWNER TO utente;

--
-- Name: collegamenti_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE collegamenti_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE collegamenti_id_seq OWNER TO utente;

--
-- Name: collegamenti_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE collegamenti_id_seq OWNED BY collegamenti.id;


--
-- Name: dadi_init; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE dadi_init (
    id_eroe integer NOT NULL,
    d1 stats,
    d2 stats,
    d3 stats,
    d4 stats,
    d5 stats
);


ALTER TABLE dadi_init OWNER TO utente;

--
-- Name: dungeons; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE dungeons (
    id integer NOT NULL,
    finale integer
);


ALTER TABLE dungeons OWNER TO utente;

--
-- Name: dungeons_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE dungeons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dungeons_id_seq OWNER TO utente;

--
-- Name: dungeons_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE dungeons_id_seq OWNED BY dungeons.id;


--
-- Name: eroi; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE eroi (
    id integer NOT NULL,
    nome text NOT NULL,
    descrizione text,
    forz stats,
    inte stats,
    cost stats,
    agil stats,
    id_utente integer NOT NULL,
    pe integer DEFAULT 0 NOT NULL,
    pf integer DEFAULT 0 NOT NULL,
    att integer DEFAULT 0 NOT NULL,
    dif integer DEFAULT 0 NOT NULL,
    per integer DEFAULT 0 NOT NULL,
    pf_scudo integer DEFAULT 0 NOT NULL,
    general_pe integer DEFAULT 0 NOT NULL,
    id_sstanza integer,
    CONSTRAINT eroi_pf_scudo_check CHECK ((pf_scudo >= 0))
);


ALTER TABLE eroi OWNER TO utente;

--
-- Name: eroi_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE eroi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE eroi_id_seq OWNER TO utente;

--
-- Name: eroi_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE eroi_id_seq OWNED BY eroi.id;


--
-- Name: nemici; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE nemici (
    id integer NOT NULL,
    nome text NOT NULL,
    descrizione text
);


ALTER TABLE nemici OWNER TO utente;

--
-- Name: nemici_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE nemici_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE nemici_id_seq OWNER TO utente;

--
-- Name: nemici_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE nemici_id_seq OWNED BY nemici.id;


--
-- Name: oggetti; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE oggetti (
    id integer NOT NULL,
    nome text NOT NULL,
    descrizione text,
    att bonus,
    dif bonus,
    pf bonus,
    per bonus,
    danno integer NOT NULL,
    tipo smallint DEFAULT 0 NOT NULL,
    CONSTRAINT oggetti_danno_check CHECK ((danno >= 0)),
    CONSTRAINT oggetti_tipo_check CHECK (((tipo >= 0) AND (tipo <= 3)))
);


ALTER TABLE oggetti OWNER TO utente;

--
-- Name: oggetti_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE oggetti_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE oggetti_id_seq OWNER TO utente;

--
-- Name: oggetti_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE oggetti_id_seq OWNED BY oggetti.id;


--
-- Name: stanze; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE stanze (
    id integer NOT NULL,
    nome text NOT NULL,
    descrizione text
);


ALTER TABLE stanze OWNER TO utente;

--
-- Name: stanze_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE stanze_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stanze_id_seq OWNER TO utente;

--
-- Name: stanze_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE stanze_id_seq OWNED BY stanze.id;


--
-- Name: stato_collegamenti; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE stato_collegamenti (
    visibile boolean DEFAULT true NOT NULL,
    id_collegamento integer NOT NULL,
    id_from_ss integer NOT NULL,
    id_to_ss integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE stato_collegamenti OWNER TO utente;

--
-- Name: stato_collegamenti_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE stato_collegamenti_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stato_collegamenti_id_seq OWNER TO utente;

--
-- Name: stato_collegamenti_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE stato_collegamenti_id_seq OWNED BY stato_collegamenti.id;


--
-- Name: stato_nemici; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE stato_nemici (
    id integer NOT NULL,
    att integer DEFAULT 0 NOT NULL,
    dif integer DEFAULT 0 NOT NULL,
    pf integer DEFAULT 0 NOT NULL,
    danno integer NOT NULL,
    id_nemico integer NOT NULL,
    id_sstanza integer NOT NULL,
    CONSTRAINT stato_nemici_danno_check CHECK ((danno > 0))
);


ALTER TABLE stato_nemici OWNER TO utente;

--
-- Name: stato_nemici_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE stato_nemici_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stato_nemici_id_seq OWNER TO utente;

--
-- Name: stato_nemici_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE stato_nemici_id_seq OWNED BY stato_nemici.id;


--
-- Name: stato_oggetti; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE stato_oggetti (
    id integer NOT NULL,
    id_oggetto integer NOT NULL,
    id_sstanza integer NOT NULL,
    visibile boolean DEFAULT true NOT NULL
);


ALTER TABLE stato_oggetti OWNER TO utente;

--
-- Name: stato_oggetti_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE stato_oggetti_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stato_oggetti_id_seq OWNER TO utente;

--
-- Name: stato_oggetti_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE stato_oggetti_id_seq OWNED BY stato_oggetti.id;


--
-- Name: stato_stanze; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE stato_stanze (
    id integer NOT NULL,
    visitata boolean DEFAULT false NOT NULL,
    id_dungeon integer NOT NULL,
    id_stanza integer NOT NULL
);


ALTER TABLE stato_stanze OWNER TO utente;

--
-- Name: stato_stanze_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE stato_stanze_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stato_stanze_id_seq OWNER TO utente;

--
-- Name: stato_stanze_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE stato_stanze_id_seq OWNED BY stato_stanze.id;


--
-- Name: utenti; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE utenti (
    id integer NOT NULL,
    mail text NOT NULL,
    nome text NOT NULL,
    password text NOT NULL,
    CONSTRAINT utenti_mail_check CHECK ((mail ~~ '_%@_%._%'::text)),
    CONSTRAINT utenti_nome_check CHECK ((nome !~~ '%@%'::text))
);


ALTER TABLE utenti OWNER TO utente;

--
-- Name: utenti_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE utenti_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE utenti_id_seq OWNER TO utente;

--
-- Name: utenti_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE utenti_id_seq OWNED BY utenti.id;


--
-- Name: zaini; Type: TABLE; Schema: space; Owner: utente
--

CREATE TABLE zaini (
    id_eroe integer NOT NULL,
    id_oggetto integer NOT NULL,
    is_equip boolean DEFAULT false NOT NULL,
    id integer NOT NULL
);


ALTER TABLE zaini OWNER TO utente;

--
-- Name: zaini_id_seq; Type: SEQUENCE; Schema: space; Owner: utente
--

CREATE SEQUENCE zaini_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE zaini_id_seq OWNER TO utente;

--
-- Name: zaini_id_seq; Type: SEQUENCE OWNED BY; Schema: space; Owner: utente
--

ALTER SEQUENCE zaini_id_seq OWNED BY zaini.id;


--
-- Name: collegamenti id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY collegamenti ALTER COLUMN id SET DEFAULT nextval('collegamenti_id_seq'::regclass);


--
-- Name: dungeons id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY dungeons ALTER COLUMN id SET DEFAULT nextval('dungeons_id_seq'::regclass);


--
-- Name: eroi id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY eroi ALTER COLUMN id SET DEFAULT nextval('eroi_id_seq'::regclass);


--
-- Name: nemici id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY nemici ALTER COLUMN id SET DEFAULT nextval('nemici_id_seq'::regclass);


--
-- Name: oggetti id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY oggetti ALTER COLUMN id SET DEFAULT nextval('oggetti_id_seq'::regclass);


--
-- Name: stanze id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stanze ALTER COLUMN id SET DEFAULT nextval('stanze_id_seq'::regclass);


--
-- Name: stato_collegamenti id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_collegamenti ALTER COLUMN id SET DEFAULT nextval('stato_collegamenti_id_seq'::regclass);


--
-- Name: stato_nemici id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_nemici ALTER COLUMN id SET DEFAULT nextval('stato_nemici_id_seq'::regclass);


--
-- Name: stato_oggetti id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_oggetti ALTER COLUMN id SET DEFAULT nextval('stato_oggetti_id_seq'::regclass);


--
-- Name: stato_stanze id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_stanze ALTER COLUMN id SET DEFAULT nextval('stato_stanze_id_seq'::regclass);


--
-- Name: utenti id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY utenti ALTER COLUMN id SET DEFAULT nextval('utenti_id_seq'::regclass);


--
-- Name: zaini id; Type: DEFAULT; Schema: space; Owner: utente
--

ALTER TABLE ONLY zaini ALTER COLUMN id SET DEFAULT nextval('zaini_id_seq'::regclass);


--
-- Data for Name: collegamenti; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY collegamenti (id, nome, descrizione) FROM stdin;
1	PORTA A SCORRIMENTO VERTICALE	Una classica porta tecnologicamente avanzata di colore grigio.
2	CORRIDOIO	Muri imbrattati di sangue... non deve essere un buon auspicio.
3	CORRIDOIO	Non vedo alieni/mostri/nemici vari in quella direzione (forse).
4	CORRIDOIO STRETTO	Questo corridoio è così stretto che a fatica riuscirai a superarlo.
5	VARCO OSCURO	Non si riesce a vedere nulla, si sente solo un forte odore di putrefazione.
\.


--
-- Data for Name: dadi_init; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY dadi_init (id_eroe, d1, d2, d3, d4, d5) FROM stdin;
\.


--
-- Data for Name: dungeons; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY dungeons (id, finale) FROM stdin;
\.


--
-- Data for Name: eroi; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY eroi (id, nome, descrizione, forz, inte, cost, agil, id_utente, pe, pf, att, dif, per, pf_scudo, general_pe, id_sstanza) FROM stdin;
\.


--
-- Data for Name: nemici; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY nemici (id, nome, descrizione) FROM stdin;
1	ALIENO DALLA TESTA OVALE	Nero, dai denti aguzzi e testa allungata. Ricorda molto l'alieno di quel film famoso.
2	VERME SPAZIALE	Tentarono di conquistare la Terra una volta.
3	DALEK	Un robot apparentemente innocuo. Non sottovalutarli, sono la nemesi del Dottore.
4	KREE	Una razza aliena dalla pelle blu, scientificamente e tecnologicamente avanzata.
5	WOOKIEE	Un grosso umanoide guerriero, molto peloso. Può essere il migliore tra gli amici o il tuo peggiore incubo (purtroppo per te è la seconda).
6	CYBORG	Un essere umano potenziato per sopravvivere in ambienti extraterrestri inospitali.
7	ROMULANO	Specie umanoide che ha distrutto il pianeta Vulcano
\.


--
-- Data for Name: oggetti; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY oggetti (id, nome, descrizione, att, dif, pf, per, danno, tipo) FROM stdin;
1	SPADA LASER	Apparteneva ad uno jedi passato al lato oscuro.	6	0	0	4	5	2
2	PIEDE DI PORCO	Arma base di qualunque gioco che si rispetti	2	1	0	0	4	2
3	FUCILE AD IMPULSI	Classico fucile delle colonie marziane.	4	0	0	0	5	2
4	CIBO IN SCATOLA	Sembrano fagioli, ma non ne sono certo	0	0	2	0	0	1
5	SCUDO DI ENERGIA	Un potentissimo scudo che crea una barriera di energia.	0	6	0	-1	0	3
6	ALIENADE PICCOLO	Integratore alimentare alieno da 50cl.	2	2	3	-1	0	0
7	ALIENADE GRANDE	Integratore alimentare alieno da 100cl.	4	4	5	-2	0	0
8	PANNELLO FOTOVOLTAICO	Può essere usato come scudo.	0	4	0	0	0	3
\.


--
-- Data for Name: stanze; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY stanze (id, nome, descrizione) FROM stdin;
1	CABINA DI PILOTAGGIO	Ci sono molte leve e bottoni, forse sarebbe meglio non toccare nulla...
2	ALLOGGIO DEL CAPITANO	C'è un letto ancorato al pavimento. La stanza è molto spoglia.
3	MENSA	Ci sono molti tavoli ancora apparecchiati e uno schermo con il piatto del giorno sul muro... la solita sbobba.
4	SALA CENTRALE	Molto ampia, con un gigantesco albero al centro.
5	SALA MACCHINE	C'è un gran baccano.
6	SMALTIMENTO RIFIUTI	Ci sono molti pezzi di ferraglia arruginita che dovrebbero essere compattati e fusi per essere riciclati.
7	IMPIANTO ENERGETICO	Sei sopra un ponte. Sotto di te, racchiusa da un guscio super avanzato, c'è una stella morente che fornisce energia all'intera astronave.
8	TEATRO	Un teatro per allietare le serate dei passeggeri.
9	SALA CINEMA	Cinema con un proiettore di ologrammi di ultima generazione.
10	TERRAZZA PANORAMICA	Una terrazza coperta da una gigantesca cupola trasparente. Prenditi un momento per osservare le stelle.
11	AREA RELAX	Ci sono molti divani che circondano una piscina. Ci sono diversi corpi senza vita a terra.
12	AREA GIOCHI	Ci sono delle piccole stanze con giochi di realtà virtuale di ultima generazione. Alcuni sono ancora collegati agli apparecchi
13	PARCO ARTIFICIALE	Un parco che contiene parte della flora e fauna terrestre.
14	BAGNO	Sembrerebbe esserci una perdita di acqua. L'acqua è molto preziosa, viene riciclata o raccolta dalle comete di passaggio. Quando finisci ricordati di ripararlo.
\.


--
-- Data for Name: stato_collegamenti; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY stato_collegamenti (visibile, id_collegamento, id_from_ss, id_to_ss, id) FROM stdin;
\.


--
-- Data for Name: stato_nemici; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY stato_nemici (id, att, dif, pf, danno, id_nemico, id_sstanza) FROM stdin;
\.


--
-- Data for Name: stato_oggetti; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY stato_oggetti (id, id_oggetto, id_sstanza, visibile) FROM stdin;
\.


--
-- Data for Name: stato_stanze; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY stato_stanze (id, visitata, id_dungeon, id_stanza) FROM stdin;
\.


--
-- Data for Name: utenti; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY utenti (id, mail, nome, password) FROM stdin;
\.


--
-- Data for Name: zaini; Type: TABLE DATA; Schema: space; Owner: utente
--

COPY zaini (id_eroe, id_oggetto, is_equip, id) FROM stdin;
\.


--
-- Name: collegamenti_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('collegamenti_id_seq', 5, true);


--
-- Name: dungeons_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('dungeons_id_seq', 186, true);


--
-- Name: eroi_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('eroi_id_seq', 79, true);


--
-- Name: nemici_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('nemici_id_seq', 7, true);


--
-- Name: oggetti_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('oggetti_id_seq', 7, true);


--
-- Name: stanze_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('stanze_id_seq', 14, true);


--
-- Name: stato_collegamenti_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('stato_collegamenti_id_seq', 802, true);


--
-- Name: stato_nemici_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('stato_nemici_id_seq', 1545, true);


--
-- Name: stato_oggetti_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('stato_oggetti_id_seq', 3105, true);


--
-- Name: stato_stanze_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('stato_stanze_id_seq', 1121, true);


--
-- Name: utenti_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('utenti_id_seq', 21, true);


--
-- Name: zaini_id_seq; Type: SEQUENCE SET; Schema: space; Owner: utente
--

SELECT pg_catalog.setval('zaini_id_seq', 468, true);


--
-- Name: collegamenti collegamenti_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY collegamenti
    ADD CONSTRAINT collegamenti_pkey PRIMARY KEY (id);


--
-- Name: dadi_init dadi_init_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY dadi_init
    ADD CONSTRAINT dadi_init_pkey PRIMARY KEY (id_eroe);


--
-- Name: dungeons dungeons_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY dungeons
    ADD CONSTRAINT dungeons_pkey PRIMARY KEY (id);


--
-- Name: eroi eroi_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY eroi
    ADD CONSTRAINT eroi_pkey PRIMARY KEY (id);


--
-- Name: nemici nemici_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY nemici
    ADD CONSTRAINT nemici_pkey PRIMARY KEY (id);


--
-- Name: oggetti oggetti_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY oggetti
    ADD CONSTRAINT oggetti_pkey PRIMARY KEY (id);


--
-- Name: stanze stanze_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stanze
    ADD CONSTRAINT stanze_pkey PRIMARY KEY (id);


--
-- Name: stato_collegamenti stato_collegamenti_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_collegamenti
    ADD CONSTRAINT stato_collegamenti_pkey PRIMARY KEY (id);


--
-- Name: stato_nemici stato_nemici_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_nemici
    ADD CONSTRAINT stato_nemici_pkey PRIMARY KEY (id);


--
-- Name: stato_oggetti stato_oggetti_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_oggetti
    ADD CONSTRAINT stato_oggetti_pkey PRIMARY KEY (id);


--
-- Name: stato_stanze stato_stanze_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_stanze
    ADD CONSTRAINT stato_stanze_pkey PRIMARY KEY (id);


--
-- Name: utenti utenti_mail_key; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY utenti
    ADD CONSTRAINT utenti_mail_key UNIQUE (mail);


--
-- Name: utenti utenti_nome_key; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY utenti
    ADD CONSTRAINT utenti_nome_key UNIQUE (nome);


--
-- Name: utenti utenti_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY utenti
    ADD CONSTRAINT utenti_pkey PRIMARY KEY (id);


--
-- Name: zaini zaini_pkey; Type: CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY zaini
    ADD CONSTRAINT zaini_pkey PRIMARY KEY (id);


--
-- Name: zaini trigger_capienza_zaino; Type: TRIGGER; Schema: space; Owner: utente
--

CREATE TRIGGER trigger_capienza_zaino BEFORE INSERT ON zaini FOR EACH ROW EXECUTE PROCEDURE capienza_zaino();


--
-- Name: zaini trigger_check_type; Type: TRIGGER; Schema: space; Owner: utente
--

CREATE TRIGGER trigger_check_type AFTER UPDATE ON zaini FOR EACH ROW WHEN (((old.is_equip IS DISTINCT FROM new.is_equip) AND (new.is_equip = true))) EXECUTE PROCEDURE check_type();


--
-- Name: eroi trigger_pf_control; Type: TRIGGER; Schema: space; Owner: utente
--

CREATE TRIGGER trigger_pf_control AFTER UPDATE ON eroi FOR EACH ROW WHEN (((new.pf <= 0) AND (new.id_sstanza IS NOT NULL))) EXECUTE PROCEDURE pf_control();


--
-- Name: eroi trigger_reset_e_attacco; Type: TRIGGER; Schema: space; Owner: utente
--

CREATE TRIGGER trigger_reset_e_attacco AFTER UPDATE ON eroi FOR EACH ROW WHEN (((old.id_sstanza IS DISTINCT FROM new.id_sstanza) AND (new.id_sstanza IS NOT NULL))) EXECUTE PROCEDURE reset_e_attacco();


--
-- Name: dadi_init dadi_init_id_eroe_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY dadi_init
    ADD CONSTRAINT dadi_init_id_eroe_fkey FOREIGN KEY (id_eroe) REFERENCES eroi(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dungeons dungeons_finale_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY dungeons
    ADD CONSTRAINT dungeons_finale_fkey FOREIGN KEY (finale) REFERENCES stato_stanze(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: eroi eroi_id_sstanza_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY eroi
    ADD CONSTRAINT eroi_id_sstanza_fkey FOREIGN KEY (id_sstanza) REFERENCES stato_stanze(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: eroi eroi_id_utente_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY eroi
    ADD CONSTRAINT eroi_id_utente_fkey FOREIGN KEY (id_utente) REFERENCES utenti(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_collegamenti stato_collegamenti_id_collegamento_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_collegamenti
    ADD CONSTRAINT stato_collegamenti_id_collegamento_fkey FOREIGN KEY (id_collegamento) REFERENCES collegamenti(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: stato_collegamenti stato_collegamenti_id_from_ss_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_collegamenti
    ADD CONSTRAINT stato_collegamenti_id_from_ss_fkey FOREIGN KEY (id_from_ss) REFERENCES stato_stanze(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_collegamenti stato_collegamenti_id_to_ss_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_collegamenti
    ADD CONSTRAINT stato_collegamenti_id_to_ss_fkey FOREIGN KEY (id_to_ss) REFERENCES stato_stanze(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_nemici stato_nemici_id_nemico_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_nemici
    ADD CONSTRAINT stato_nemici_id_nemico_fkey FOREIGN KEY (id_nemico) REFERENCES nemici(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_nemici stato_nemici_id_sstanza_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_nemici
    ADD CONSTRAINT stato_nemici_id_sstanza_fkey FOREIGN KEY (id_sstanza) REFERENCES stato_stanze(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_oggetti stato_oggetti_id_oggetto_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_oggetti
    ADD CONSTRAINT stato_oggetti_id_oggetto_fkey FOREIGN KEY (id_oggetto) REFERENCES oggetti(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_oggetti stato_oggetti_id_sstanza_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_oggetti
    ADD CONSTRAINT stato_oggetti_id_sstanza_fkey FOREIGN KEY (id_sstanza) REFERENCES stato_stanze(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_stanze stato_stanze_id_dungeon_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_stanze
    ADD CONSTRAINT stato_stanze_id_dungeon_fkey FOREIGN KEY (id_dungeon) REFERENCES dungeons(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stato_stanze stato_stanze_id_stanza_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY stato_stanze
    ADD CONSTRAINT stato_stanze_id_stanza_fkey FOREIGN KEY (id_stanza) REFERENCES stanze(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: zaini zaini_id_eroe_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY zaini
    ADD CONSTRAINT zaini_id_eroe_fkey FOREIGN KEY (id_eroe) REFERENCES eroi(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: zaini zaini_id_oggetto_fkey; Type: FK CONSTRAINT; Schema: space; Owner: utente
--

ALTER TABLE ONLY zaini
    ADD CONSTRAINT zaini_id_oggetto_fkey FOREIGN KEY (id_oggetto) REFERENCES oggetti(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

