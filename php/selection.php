<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */
?>

<div class="container text-center" >
    <div class="row">
        <div class="col-sm-offset-1 col-sm-10 col-xs-12">
        <?php
        $stmt = pg_query_params($db,"SELECT * FROM eroi WHERE id_utente=$1",array($_SESSION['usid']));
        if(!$stmt)
            $err->to_back(pg_last_error($db),$db);
        while(($row=pg_fetch_array($stmt)))
        {
            echo '<form action="adventure.php" method="post" > <input type="hidden" name="idero" value="'.$row['id'].'"> <input type="hidden" name="gpe" value="'.$row['general_pe'].'">
            <div class="row thumbnail" style="padding:0; position:relative; ">
                <div class="col-xs-8 no_pad_mar">
                    <h5>'.$row['nome'].' - '.$row['descrizione'].'</h5>
                    <h6>
                    <div class="col-xs-12 col-sm-3 no_pad_mar">Forza: '.$row['forz'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Intelligenza: '.$row['inte'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Costituzione: '.$row['cost'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Agilità: '.$row['agil'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Attacco: '.$row['att'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Difesa: '.$row['dif'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Percezione: '.$row['per'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Punti Ferita: '.$row['pf'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Punti Ferita Scudo: '.$row['pf_scudo'].
                    '</div><div class="col-xs-12 col-sm-3 no_pad_mar">Punti Esperienza Totali: '.$row['general_pe'].
                    '</div></h6>
                </div>
                <div class="col-xs-4 text-right btn-group" style="padding:0; height: 100%;">
                    <input style="height: 100%; width:80%;" type="submit" name="go" value = "Inizia Avventura" class="btn btn-primary">
                    <button style="height: 100%; width:20%;" class="btn btn-primary" type="submit" name="remove" value="1"><i class="glyphicon glyphicon-remove"></i></button>
                </div>
            </div>
            </form>';
        }
        ?>
        </div>
    </div>

    <div class="row" style="margin-top: 2%;">
        <form method="post" action="crea.php">
            <div class="row" style="margin-bottom: 3%;">
                <div class="col-xs-12">
                    <h3>Crea nuovo eroe</h3>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-4 col-xs-offset-2">
                    <input type="text" required placeholder = "Nome" name="nome" class="form-control">
                </div>
                <div class="col-xs-4">
                    <textarea type="text" placeholder = "Descrizione" name="descr" class="form-control" style="overflow: auto;"></textarea>
                </div>
            </div>
            <div class="row" style="margin-top: 2%;">
                <div class="col-xs-12">
                    <input type="submit" name="crea" value = "Crea" class="btn btn-primary">
                </div>
            </div>
        </form>
    </div>

</div>
