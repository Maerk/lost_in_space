<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*        Copyright 2018 Marco De Nicolo
*/
?>
<script>
    function controllo(col, row)
    {
        var cont = 0;
        for(var r=0; r<4; r++)
        {
            var el = document.getElementById("d"+col+""+r);
            if(el.checked && r!=row)
                el.checked = false;
        }
    }
</script>
<div class="col-xs-12 col-sm-6 col-sm-offset-3">
    <form action="startgame.php" method="post">
        <div class="table-responsive">
            <table class="table table-bordered">
                <thead>
                    <tr>
                        <th>STATS</th>
                        <?php
                        for($j=0;$j<5;$j++)
                        {
                            echo '<th>'.$valdado[$j].'</th>';
                        }
                        ?>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    $stat = array("Forza", "Intelligenza", "Costituzione", "Agilità");
                    for($i=0; $i<count($stat); $i++)
                    {
                        echo '<tr><td>'.$stat[$i].'</td>';
                        for($j=0;$j<5;$j++)
                        {
                            echo '<td><input type="radio" value="'.($j+1).'" name="'.$stat[$i].'" id="d'.$j.$i.'" class="input-form"  onclick="controllo('.$j.', '.$i.')"></td>';
                        }
                        echo '</tr>';
                    }
                    ?>
                </tbody>
            </table>
        </div>
        <div class="text-center" style="margin-top:2%;">
            <input type="submit" name="app" value = "Applica" class="btn btn-primary">
        </div>
    </form>
</div>
