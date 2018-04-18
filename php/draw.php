<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

    class draw
    {
        private $active;
        function __construct($active_num)
        {
            $this->active = $active_num;
        }
        function draw_navbar()
        {
            $str = "";
            $str .= '
            <div class="navbar navbar-default" role="navigation">
    		  <div class="container-fluid">

    			<div class="navbar-header">
                    <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#myNavbar">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </button>
    				<a href="index.php">
    					<img style="max-height:70px; min-width: 150px; " src="img/lost_in_space.png" alt="no_logo">
    				</a>
    			</div>

    			<div class="collapse navbar-collapse" id="myNavbar">
    			  <ul style="min-height:100%; overflow:auto;" class="nav navbar-nav navbar-right">';
    				if(isset($_SESSION['logged']) && $_SESSION['logged'])
    				{
    							$str .= '<li style="margin-top:25px; color: white; font-size:1em; font-family:Tahoma, Arial, Helvetica, sans-serif;"><div class="col-xs-12">Nickname: '.$_SESSION['name'].' </div></li>
                                <li class=" '.($act=($this->active==0? "active" : "")).'"><a href="index.php" style="height: 70px; padding-top:25px;"><span class="glyphicon glyphicon-home"></span> Home</a></li>';
    					$str .= '<li ><a href="logout.php" style="height: 70px; padding-top:25px;"><span class="glyphicon glyphicon-log-out"></span>Logout</a></li>';
    				}
    				else
    				{
    					$str .= '<li class=" '.($act=($this->active==0? "active" : "")).'"><a href="index.php" style="height: 70px; padding-top:25px;"><span class="glyphicon glyphicon-home"></span> Home</a></li>';
    				}
    			 $str.='
    			  </ul>
    			</div>

    		  </div>
          </div>';
          return $str;
        }
    }
?>
