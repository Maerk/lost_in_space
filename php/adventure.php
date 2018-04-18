<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

session_start();
if(!isset($_SESSION['logged']) || $_SESSION['logged'] == 0)
    header('Location: index.php');
include 'postgres.php';
include 'draw.php';
include 'errors.php';
$psg = new postgres();
$dr = new draw(1);
$err = new errors("index.php","err");
$play = false;
if(!($db = $psg->my_db()))
	$err->to_back("Unable to open DB");

/*remove*/
if(isset($_POST['remove']))
{
    if(!isset($_POST['idero']))
        $err->to_back("Failed! There's a problem with your data.",$db);
    $stmt = pg_query_params($db,"DELETE FROM dungeons WHERE id = (SELECT id_dungeon FROM stato_stanze JOIN eroi ON eroi.id_sstanza=stato_stanze.id WHERE eroi.id=$1)",array($_POST['idero']));
    $stmt = pg_query_params($db,"DELETE FROM eroi WHERE id = $1",array($_POST['idero']));
    header("Location: index.php");
}
/*controllo*/
if(!isset($_POST['idero']) && !isset($_SESSION['idero']))
    $err->to_back("Failed! There's a problem with your data.",$db);
if(isset($_POST['idero']))
    $_SESSION['idero'] = $_POST['idero'];
$stmt = pg_query_params($db,"SELECT id_utente FROM eroi WHERE id=$1",array($_SESSION['idero']));
if(!$stmt)
    $err->to_back(pg_last_error($db),$db);
$row = pg_fetch_array($stmt);
if($_SESSION['usid'] != $row[0])
    $err->to_back("Error! The hero doesn't exists.",$db);

/*leggo valori dadi*/
$stmt = pg_query_params($db,"SELECT d1,d2,d3,d4,d5 FROM dadi_init WHERE id_eroe=$1",array($_SESSION['idero']));
if(!$stmt)
    $err->to_back(pg_last_error($db),$db);
$valdado = pg_fetch_array($stmt);
if(empty($valdado))
    //gioca
    $play = true;
    //else scegli i dadi
 ?>
 <!DOCTYPE html>
 <html>
     <head>
         <?php include 'inithtml.php'; ?>
     </head>
     <body>
 		<div style="overflow-x: hidden; height: 100%;">
            <?php
    		echo $dr->draw_navbar();
            if(!$play)
                include 'dicetab.php';
            else
                include 'game.php';
            echo $err->draw_bar("err", "succ");
            ?>
        </div>
    </body>
</html>
