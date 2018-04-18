<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

session_start();
if(!isset($_SESSION['logged']) || $_SESSION['logged'] == 0)
    header('Location: index.php');
include 'postgres.php';
include 'errors.php';
$psg = new postgres();
$err = new errors("index.php","err");
if(!($db = $psg->my_db()))
	$err->to_back("Unable to open DB");

if(!isset($_SESSION['usid']) || !isset($_POST['nome']) || !isset($_POST['descr']))
    $err->to_back("Failed! There's a problem with your data.",$db);
/*init eroe*/
$stmt = pg_query_params($db,"SELECT * FROM ini_eroe($1,$2,$3)",array($_SESSION['usid'],$_POST['nome'], $_POST['descr']));
if(!$stmt)
    $err->to_back(pg_last_error($db),$db);
$id_eroe = pg_fetch_array($stmt)[0];
/*lancio dadi*/
$stmt = pg_query_params($db,"SELECT * FROM lancio_dadi($1)",array($id_eroe));
if(!$stmt)
    $err->to_back(pg_last_error($db),$db);
header('Location: index.php?succ=Success')
?>
