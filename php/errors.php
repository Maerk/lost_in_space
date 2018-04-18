<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*        Copyright 2018 Marco De Nicolo
*/

    class errors
    {
        private $loc_str;
        private $text_id;
        private $inhib;
        function __construct($location_str, $text_id, $inhibit=false)
        {
            $this->loc_str = $location_str;
            $this->text_id = $text_id;
            $this->inhib = $inhibit;
        }
        function to_back($err_str, $db=NULL)
        {
            if($this->inhib)
            {echo 'inhibit'; die();}
            if($db)
                pg_close($db);
            header("Location: ".$this->loc_str."?".$this->text_id."=".$err_str."");
        }
        function draw_bar($err_name, $succ_name)
        {
            $str = '<div class="row text-center" style="padding:0; margin-top:1%;">';
        				 if(isset($_GET[$err_name])){$str .= '<div class="container text-center"><label class="control-label" style="color:red;">'.$_GET[$err_name].'</label></div>';}
        			     if(isset($_GET[$succ_name])){$str .= '<div class="container text-center"><label class="control-label" style="color:green;">'.$_GET[$succ_name].'</label></div>';}
        	$str .=	'</div>';
            return $str;
        }
    }
?>
