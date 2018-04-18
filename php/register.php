<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

session_start();
include 'postgres.php';
include 'errors.php';
$psg = new postgres();
$err = new errors("index.php","err");
if(!($db = $psg->my_db()))
	$err->to_back("Unable to open DB");
//reg
if(isset($_POST['reg']) && $_POST['reg'] && isset($_POST['nick']) && isset($_POST['email']) && isset($_POST['password']))
{
    $stmt = pg_query_params($db, "SELECT * FROM crea_utente($1,$2,$3)",array($_POST['nick'],$_POST['email'],$_POST['password']));
	if(!$stmt)
	    $err->to_back(pg_last_error($db),$db);
}
else
	$err->to_back("Failed! There's a problem with your data.",$db);
pg_close($db);
header("Location: index.php?succ=Success");
?>
