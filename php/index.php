<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*        Copyright 2018 Marco De Nicolo
*/

session_start();
include 'postgres.php';
include 'draw.php';
include 'errors.php';
$err = new errors("index.php","err");
$psg = new postgres();
$dr = new draw(0);
if(!($db = $psg->my_db()))
{
	echo "Unable to open DB";
	die();
}
?>

<!DOCTYPE html>
<html>
    <head>
        <?php include 'inithtml.php'; ?>
    </head>
    <body>
		<div style="overflow-x: hidden;">
		<?php
		echo $dr->draw_navbar();
		if((!isset($_SESSION['logged']) || $_SESSION['logged']==0))
		{
			include 'logreg.php';
		}
		else
		{
			include 'selection.php';
		}
			echo $err->draw_bar("err", "succ");
		?>
		</div>
    </body>
</html>

<?php
pg_close($db);
?>
