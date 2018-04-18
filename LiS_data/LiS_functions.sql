/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
* 
*        Copyright 2018 Marco De Nicolo
*/

CREATE LANGUAGE plpython3u;

/*registrazione utente*/
CREATE OR REPLACE FUNCTION crea_utente(nome TEXT, mail TEXT, upassword TEXT)
RETURNS VOID AS $$
from Crypto.Protocol.KDF import PBKDF2
pas = PBKDF2(upassword,b'\x83)\x95\xf0\xc6P\\\x9f').hex()
plan = plpy.prepare("INSERT INTO utenti(nome,mail,password) VALUES($1,$2,$3)",["text","text","text"])
plpy.execute(plan,[nome,mail,pas])
$$ LANGUAGE plpython3u;

/*login, ritorna true se le credenziali sono valide*/
CREATE OR REPLACE FUNCTION login_utente(nomemail TEXT, upassword TEXT)
RETURNS BOOLEAN AS $$
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
$$ LANGUAGE plpython3u;

/*inizio a creare l'eroe, ritorna id_eroe*/
CREATE OR REPLACE FUNCTION ini_eroe(id_utente INTEGER, nome TEXT, descrizione TEXT)
RETURNS INTEGER AS $$
plan = plpy.prepare("INSERT INTO eroi(nome, descrizione, id_utente) VALUES($1,$2,$3)",["text","text","integer"])
plpy.execute(plan,[nome,descrizione,id_utente])
return plpy.execute("SELECT last_value FROM eroi_id_seq")[0]["last_value"]
$$ LANGUAGE plpython3u;

/*lancio dei dadi e azzero eroe*/
CREATE OR REPLACE FUNCTION lancio_dadi(id_eroe INTEGER)
RETURNS VOID AS $$
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
$$ LANGUAGE plpython3u;

/*finisco di creare l'eroe, gli passo i nomi  dei campi della tabella dadi_init*/
CREATE OR REPLACE FUNCTION fin_eroe(id_eroe INTEGER, forz TEXT, inte TEXT, cost TEXT, agil TEXT)
RETURNS VOID AS $$
plan = plpy.prepare("SELECT d1,d2,d3,d4,d5 FROM dadi_init WHERE id_eroe=$1",["integer"])
ret = plpy.execute(plan,[id_eroe])
plan = plpy.prepare("UPDATE eroi SET forz=$1, inte=$2, cost=$3, agil=$4, pf=$3, att=round(($1+$4)/2.0), dif=round(($3+$4)/2.0), per=$2 WHERE id=$5",["integer","integer","integer","integer","integer"])
plpy.execute(plan,[ret[0][forz],ret[0][inte],ret[0][cost],ret[0][agil],id_eroe])
plan = plpy.prepare("DELETE FROM dadi_init WHERE id_eroe=$1",["integer"])
plpy.execute(plan,[id_eroe])
$$ LANGUAGE plpython3u;

/*creo la mappa di gioco: stato_stanze sono i nodi e stato_collegamenti gli archi*/
CREATE OR REPLACE FUNCTION crea_dungeon(id_eroe INTEGER)
RETURNS VOID AS $$
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
#0<pEasy<=1, ad 1 è più facile sconfiggere i nemici
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
$$ LANGUAGE plpython3u;

/*dato un sstanza restituisco le stanze adiacenti ((id_sstanza,visibile,nome_stanza,nome_col,descrizione_col), ...)*/
CREATE OR REPLACE FUNCTION adia_stanza(sstanza INTEGER)
RETURNS TABLE(id_sstanza INTEGER, visibile BOOLEAN, nome_stanza TEXT, visitata BOOLEAN, nome_collegamento TEXT, descrizione_collegamento TEXT)
AS $$
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
$$ LANGUAGE plpython3u;

/*modifico att,dif,per,pf del mio eroe Add = t -> aggiungo l'oggetto, Add = f -> tolgo oggetto*/
CREATE OR REPLACE FUNCTION equip_obj(id_eroe INTEGER, id_obj INTEGER, add BOOLEAN)
RETURNS VOID AS $$
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
$$ LANGUAGE plpython3u;

/*nella prima parte attacco eroe->nemico, poi nemici->eroe se ancora vivo. Tolgo prima i pv_scudo e poi i pv*/
CREATE OR REPLACE FUNCTION attacco(id_eroe INTEGER, id_nemico INTEGER)
RETURNS VOID AS $$
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
$$ LANGUAGE plpython3u;

/*rendo visibili passaggi o oggetti se 1d20 < per*/
CREATE OR REPLACE FUNCTION segreti(id_eroe INTEGER)
RETURNS VOID AS $$
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
$$ LANGUAGE plpython3u;
