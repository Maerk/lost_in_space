<!-- This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*        Copyright 2018 Marco De Nicolo
-->

<script>
    function controllo(pass,pass_rep,stmp)
    {
        var p = pass.value;
        var rep = pass_rep.value;
        if(p != rep)
        {
            stmp.innerHTML = "Error! Passwords are different.";
            return false;
        }
        else
        {
            stmp.innerHTML = "";
            return true;
        }
    }
</script>

<div class="row text-center" style="padding:0;">

    <div class="col-sm-6 col-xs-12">
        <div class="row">
            <div class="col-sm-7 col-sm-offset-4 col-xs-12">
        			<form method="post" action="enter.php"><br>
        				<input type="text" required placeholder = "Nickname o Email" name="user" class="form-control"><br>
        				<input type="password" required placeholder = "Password" name="password" class="form-control"><br>
        				<input type="submit" name="login" value = "Login" class="btn btn-primary "><br>
        			</form>
            </div>
        </div>
    </div>

    <div class="col-sm-6 col-xs-12">
        <div class="row">
            <div class="col-sm-7 col-sm-offset-1 col-xs-12">
        			<form method="post" action="register.php"><br>
        				<input type="text" required placeholder = "Nickname" name="nick" class="form-control"><br>
                        <input type="text" required placeholder = "Email" name="email" class="form-control"><br>
        				<input type="password" required placeholder = "Password" name="password" class="form-control" id="pass"><br>
                        <input type="password" required placeholder = "Ripeti Password" class="form-control" id="rep_pass"><br>
                        <div class="row"><div class="col-xs-12"><p id="pa" style="color:red;"></p></div></div>
        				<input type="submit" name="reg" value = "Registrati" class="btn btn-primary " onclick="return controllo(document.getElementById('pass'),document.getElementById('rep_pass'),document.getElementById('pa'))"><br>
        			</form>
            </div>
        </div>
    </div>

</div>
