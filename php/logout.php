<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

session_start();
if(isset($_SESSION['logged']))
{
		$_SESSION['logged'] = 0;
}
header("Location: index.php");
?>
