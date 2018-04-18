<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*        Copyright 2018 Marco De Nicolo
*/

session_start();
if(!isset($_SESSION['logged']) || $_SESSION['logged'] == 0)
    header('Location: index.php');
include 'postgres.php';
include 'errors.php';
$psg = new postgres();
$err = new errors("adventure.php","err");
if(!($db = $psg->my_db()))
	$err->to_back("Unable to open DB");


if(!isset($_SESSION['usid']) || !isset($_SESSION['idero']) || !isset($_POST['Forza'])  || !isset($_POST['Intelligenza']) || !isset($_POST['Costituzione']) || !isset($_POST['Agilità']))
    $err->to_back("Failed! There's a problem with your data.",$db);
/*fin eroe*/
foreach($arr=array($_POST["Forza"], $_POST["Intelligenza"], $_POST["Costituzione"], $_POST["Agilità"]) as $key => $val)
{
    for($i=$key+1; $i<count($arr);$i++)
    {
        if($arr[$i] == $val)
            $err->to_back("Failed! There's a problem with your data. (Multiple data)",$db);
    }
}
$stmt = pg_query_params($db,"SELECT * FROM fin_eroe($1,$2,$3,$4,$5)",array($_SESSION['idero'],'d'.$_POST['Forza'],'d'.$_POST['Intelligenza'],'d'.$_POST['Costituzione'],'d'.$_POST['Agilità']));
if(!$stmt)
    $err->to_back(pg_last_error($db),$db);
$stmt = pg_query_params($db,"SELECT * FROM crea_dungeon($1)",array($_SESSION['idero']));
if(!$stmt)
    $err->to_back(pg_last_error($db),$db);
header('Location: adventure.php');
?>
