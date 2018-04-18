<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class postgres
{
    function my_db()
    {
        $db = pg_connect("host=localhost port=5432 dbname=LiS user=user password=password");
        pg_query($db,"SET search_path TO space");
        return $db;
    }
}
?>
