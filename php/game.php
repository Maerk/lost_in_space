<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*        Copyright 2018 Marco De Nicolo
*/

if(!isset($_SESSION['logged']) || $_SESSION['logged'] == 0)
    header('Location: index.php');

if(isset($_POST['nstanza']))
{
    pg_query_params($db,"UPDATE eroi SET id_sstanza = $1 WHERE id=$2",array($_POST['nstanza'],$_SESSION['idero']));
}

if(isset($_POST['take']))
{
    $num = pg_fetch_array(pg_query_params($db,"SELECT COUNT(id_oggetto) AS peso FROM zaini WHERE id_eroe=$1",array($_SESSION['idero'])))["peso"];
    pg_query_params($db,"INSERT INTO zaini(id_eroe,id_oggetto) VALUES($1,(SELECT id_oggetto FROM stato_oggetti WHERE id=$2))",array($_SESSION['idero'],$_POST['take']));
    $num2 = pg_fetch_array(pg_query_params($db,"SELECT COUNT(id_oggetto) AS peso FROM zaini WHERE id_eroe=$1",array($_SESSION['idero'])))["peso"];
    if($num2>$num)
        pg_query_params($db,"DELETE FROM stato_oggetti WHERE id=$1",array($_POST['take']));
}

if(isset($_POST['use']))
{
//set is_equp=t e parte il trigger
    pg_query_params($db,"UPDATE zaini SET is_equip = $1 WHERE id = $2",array(true, $_POST['use']));
}

if(isset($_POST['attack']))
{
    pg_query_params($db,"SELECT * FROM attacco($1,$2)",array($_SESSION['idero'],$_POST['attack']));
}

if(isset($_POST['search']))
{
    pg_query_params($db,"SELECT * FROM segreti($1)",array($_SESSION['idero']));
}
$stmt = pg_query_params($db,"SELECT eroi.id_sstanza,eroi.att,eroi.dif,eroi.per,eroi.pf,eroi.pf_scudo,eroi.general_pe FROM eroi WHERE id =$1",array($_SESSION['idero']));
$val = pg_fetch_array($stmt);
if($val["id_sstanza"]==Null)
{
    if(isset($_POST["gpe"]) && $_POST["gpe"] < $val["general_pe"])
    {
        echo "<div class='row text-center'><h1>HAI VINTO!</h1></div>";
        die();
    }
    else
        header('Location: index.php');
}
else
{
    $stmt = pg_query_params($db,"SELECT stanze.nome,stanze.descrizione,stato_stanze.id,stato_stanze.id_dungeon FROM stanze JOIN stato_stanze ON stanze.id=stato_stanze.id_stanza WHERE stato_stanze.id=$1",array($val["id_sstanza"]));
    $val = array_merge($val,pg_fetch_array($stmt));
}
if(isset($_POST['drop']))
{
    pg_query_params($db,"INSERT INTO stato_oggetti(id_oggetto,id_sstanza) VALUES((SELECT id_oggetto FROM zaini WHERE id = $1),$2)",array($_POST['drop'],$val["id"]));
    pg_query_params($db,"DELETE FROM zaini WHERE id=$1",array($_POST['drop']));
}
?>
<form action="adventure.php" method="post"><input type="hidden" name="gpe" value="<?php echo $val['general_pe'];?>">
<div class="container" style="height: 70%;">
    <div class="row">
        <div class="col-xs-10 col-xs-offset-1">
            <div class="row no_pad_mar text-center">
                <div class="col-xs-12"><?php echo $val["id"]." - ".$val["nome"]; ?></div>
            </div>
            <div class="row no_pad_mar text-center">
                <div class="col-xs-12"><?php echo $val["descrizione"]; ?></div>
            </div>
        </div>
    </div>

    NEMICI:
    <div class="row">
        <?php
        $stmt = pg_query_params($db,"SELECT stato_nemici.id,stato_nemici.att,stato_nemici.dif,stato_nemici.pf,stato_nemici.danno,nemici.nome,nemici.descrizione FROM stato_nemici JOIN nemici ON stato_nemici.id_nemico=nemici.id WHERE stato_nemici.id_sstanza=$1",array($val["id"]));
        $search = true;
        while(($row = pg_fetch_array($stmt)))
        {
            $search = false;
            echo '<div class="col-xs-4 thumbnail" style="margin: 0; border-color:grey;">
                    <div class="col-xs-9 no_pad_mar">
                        <div class="row no_pad_mar">'.$row["nome"].': '.$row["descrizione"].'</div>
                        <div class="row no_pad_mar">ATT: '.$row["att"].', DIF: '.$row["dif"].', DANNO: '.$row["danno"].', PF: '.$row["pf"].'</div>
                    </div>
                    <div class="col-xs-3 no_pad_mar text-center">
                        <button type="submit" name="attack" value="'.$row["id"].'" class="btn btn-primary">ATTACCA</button>
                    </div>
                </div>';
        }
        ?>
    </div>

    OGGETTI:
    <div class="row">
        <?php
        $stmt = pg_query_params($db,"SELECT * FROM stato_oggetti JOIN oggetti ON oggetti.id=stato_oggetti.id_oggetto WHERE stato_oggetti.id_sstanza = $1 AND stato_oggetti.visibile = 't' ",array($val["id"]));
        while(($row = pg_fetch_array($stmt)))
        {
            $testo_pf="PF";
            $color = "grey";
            if ($row["tipo"] == 2) $color = "red"; elseif($row["tipo"] == 3) $color = "blue"; elseif($row["tipo"] == 0) {$color="orange"; $testo_pf="SCUDO";}
            echo '<div class="col-xs-4 thumbnail" style="margin: 0; border-color:'.$color.';"><div class="col-xs-10"><div class="row no_pad_mar">'.$row["nome"].': '.$row["descrizione"].'</div>
                <div class="row no_pad_mar">ATT: '.$row["att"].', DIF: '.$row["dif"].', PER: '.$row["per"].', '.$testo_pf.': '.$row["pf"].', DANNO: '.$row["danno"].'</div></div><div class="col-xs-2"><button type="submit" name="take" value="'.$row[0].'" class="btn btn-default"><i class="glyphicon glyphicon-hand-left"></i></button></div></div>';
        }
        ?>
    </div>

    STANZE:
    <div class="row">
        <?php
        $stmt = pg_query_params($db,"SELECT * FROM adia_stanza($1)",array($val["id"]));
        while(($row = pg_fetch_array($stmt)))
        {
            if($row["visitata"] == 't' && $row["visibile"] == 't' || $row["visibile"] == 't' && $search)
                echo '<div class="col-xs-4 thumbnail ">
                        <div class="row no_pad_mar text-center">
                            <button class="btn btn-primary" type="submit" name="nstanza" value="'.$row["id_sstanza"].'">'.$row["id_sstanza"].' - '.$row["nome_stanza"].'</button>
                        </div>
                        <div class="row no_pad_mar">'. $row["nome_collegamento"] .':  '. $row["descrizione_collegamento"].'</div>
                     </div>' ;
                }
        ?>
    </div>

    <?php
    /*cerca segreti*/
    if($search)
    {
        echo '<div class="row"><div class="col-xs-4 col-xs-offset-4 thumbnail">
            <div class="row no_pad_mar text-center"><button class="btn btn-primary" name="search">CERCA SEGERTI</button></div>
            <div class="row no_pad_mar no_pad_mar">Usa un PF per cercare un passaggio segreto o un oggetto nascosto. Aumenta PERCEZIONE per avere maggiori probabilità di successo</div>
            </div></div>';
    }
    ?>
</div>
<div class="row"><div class="col-xs-6 col-xs-offset-3 thumbnail text-center" style="margin-top: 20px;">
    <div class="row no_pad_mar"><div class="col-xs-2 col-xs-offset-1"><?php echo "ATT";?></div><div class="col-xs-2"><?php echo "DIF";?></div> <div class="col-xs-2"><?php echo "PER";?></div><div class="col-xs-2"><?php echo "PF";?> </div><div class="col-xs-2"><?php echo "SCUDO";?></div></div>
    <div class="row no_pad_mar"><div class="col-xs-2 col-xs-offset-1"><?php echo $val["att"];?></div><div class="col-xs-2"><?php echo $val["dif"];?></div> <div class="col-xs-2"><?php echo $val["per"];?></div><div class="col-xs-2" style="color:red;"><?php echo $val["pf"];?> </div><div class="col-xs-2" style="color:orange;"><?php echo $val["pf_scudo"];?></div></div>
</div></div>
<footer class="footer">
    <div class="container">
        <div class="row"> <span class="text-muted">Zaino</span> </div>
        <div class="row"><?php
        $stmt =  pg_query_params($db,"SELECT zaini.id,tipo,is_equip,att,dif,per,pf,danno,nome,descrizione FROM zaini JOIN oggetti ON zaini.id_oggetto=oggetti.id WHERE zaini.id_eroe=$1",array($_SESSION["idero"]));
        while(($row = pg_fetch_array($stmt)))
        {
            $testo_pf = "PF";
            $color = "grey";
            if ($row["tipo"] == 2) $color = "red"; elseif($row["tipo"] == 3) $color = "blue"; elseif($row["tipo"] == 0) {$color="orange"; $testo_pf="SCUDO";}
            $inner_color = $row["is_equip"] == 't'? "#adebad" : "white";
            echo '<div class="col-xs-4 thumbnail" style="margin: 0; background-color:'.$inner_color.'; border-color:'.$color.';"><div class="col-xs-9 no_pad_mar"><div class="row no_pad_mar">'.$row["nome"].': '.$row["descrizione"].'</div>
                <div class="row no_pad_mar">ATT: '.$row["att"].', DIF: '.$row["dif"].', PER: '.$row["per"].', '.$testo_pf.': '.$row["pf"].', DANNO: '.$row["danno"].'</div></div><div class="col-xs-3 no_pad_mar text-center">';
            if($row["is_equip"] == 'f')
            {
                echo '<div class="btn-group-vertical"><button type="submit" class="btn btn-default btn-lg" name="use" value="'.$row["id"].'"><span class="glyphicon glyphicon-plus"></span>Usa</button>
                      <button class="btn btn-default" name="drop" value="'.$row["id"].'"><i class="glyphicon glyphicon-trash"></i></button></div>';
            }
            echo '</div></div>';
        }
        ?></div>
    </div>
</footer>
</form>
