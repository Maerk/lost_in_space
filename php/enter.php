<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

session_start();
include 'postgres.php';
include 'errors.php';
$psg = new postgres();
$err = new errors("index.php", "err");
if(!($db = $psg->my_db()))
	$err->to_back("Unable to open DB");
    //login_utente
    if(isset($_POST['login']) && $_POST['login'] && $_POST['user'] && $_POST['password'])
    {
        $stmt = pg_query_params($db, "SELECT * FROM login_utente($1,$2)",array($_POST['user'],$_POST['password']));
		if(!$stmt)
		    $err->to_back(pg_last_error($db),$db);
		$row = pg_fetch_array($stmt);
		if($row[0] == 't')
		{
			$_SESSION['logged'] = 1;
			$_SESSION['name'] = $_POST['user'];
			$stmt = pg_query_params($db,"SELECT id FROM utenti WHERE nome=$1 OR mail=$1",array($_POST['user']));
			if(!$stmt)
				$err->to_back(pg_last_error($db),$db);
			$_SESSION['usid'] = pg_fetch_array($stmt)[0];
		}
		else
			$err->to_back("The user and password you entered did not match.",$db);
}
pg_close($db);
header("Location: index.php");
?>
