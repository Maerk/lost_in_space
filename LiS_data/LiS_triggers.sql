/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
* 
*        Copyright 2018 Marco De Nicolo
*/

/*gestione zaino (capacità max = ceil(cos/2)) se ci sta lo metto e tolgo l'oggetto dalla stanza, else skip*/
CREATE OR REPLACE FUNCTION capienza_zaino()
    RETURNS TRIGGER
AS $$
from math import ceil
plan = plpy.prepare("SELECT cost FROM eroi WHERE id=$1",["integer"])
cost = plpy.execute(plan,[TD["new"]["id_eroe"]])[0]["cost"]
plan = plpy.prepare("SELECT COUNT(id_oggetto) AS peso FROM zaini WHERE id_eroe=$1",["integer"])
peso = plpy.execute(plan,[TD["new"]["id_eroe"]])[0]["peso"]
if(peso+1 > ceil(cost/2)):
    return "SKIP"
return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_capienza_zaino BEFORE INSERT ON zaini FOR EACH ROW EXECUTE PROCEDURE capienza_zaino();

/*tolgo oggetti usati nella vecchia stanza e i nemici mi attaccano*/
CREATE OR REPLACE FUNCTION reset_e_attacco()
    RETURNS TRIGGER
AS $$
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
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_reset_e_attacco AFTER UPDATE ON eroi FOR EACH ROW WHEN (OLD.id_sstanza IS DISTINCT FROM NEW.id_sstanza AND NEW.id_sstanza IS DISTINCT FROM NULL) EXECUTE PROCEDURE reset_e_attacco();

/*controllo se la stanza è collegata*//*
CREATE OR REPLACE FUNCTION check_link()
    RETURNS TRIGGER
AS $$
plan = plpy.prepare("SELECT * FROM stato_collegamenti WHERE visibile = $1 AND ((id_from_ss = $2 AND id_to_ss = $3) OR (id_from_ss = $3 AND id_to_ss = $2))",["boolean","integer","integer"])
ris = plpy.execute(plan,[True, TD["old"]["id_sstanza"], TD["new"]["id_sstanza"]])
if not ris:
    return "SKIP"
return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_check_link BEFORE UPDATE ON eroi FOR EACH ROW WHEN (OLD.id_sstanza IS DISTINCT FROM NULL AND OLD.id_sstanza IS DISTINCT FROM NEW.id_sstanza) EXECUTE PROCEDURE check_link();
*/
/*quando equipaggio un oggetto di tipo 2 o 3 controllo che sia l'unico, se non lo è tolgo quello vecchio. Equipaggio gli altri oggetti*/
CREATE OR REPLACE FUNCTION check_type()
    RETURNS TRIGGER
AS $$
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
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_check_type AFTER UPDATE ON zaini FOR EACH ROW WHEN (OLD.is_equip IS DISTINCT FROM NEW.is_equip AND NEW.is_equip = 't') EXECUTE PROCEDURE check_type();

/*controllo pf*/
CREATE OR REPLACE FUNCTION pf_control()
    RETURNS TRIGGER
AS $$
plan = plpy.prepare("DELETE FROM dungeons WHERE id = (SELECT id_dungeon FROM stato_stanze WHERE id =$1)",["integer"])
plpy.execute(plan,[TD["new"]["id_sstanza"]])
plan = plpy.prepare("SELECT * FROM lancio_dadi($1)",["integer"])
plpy.execute(plan,[TD["new"]["id"]])
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_pf_control AFTER UPDATE ON eroi FOR EACH ROW WHEN (NEW.pf <= 0 AND NEW.id_sstanza IS DISTINCT FROM NULL) EXECUTE PROCEDURE pf_control();
