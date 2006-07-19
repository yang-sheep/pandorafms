<?php

// Pandora - the Free monitoring system
// ====================================
// Copyright (c) 2004-2006 Sancho Lerena, slerena@gmail.com
// Copyright (c) 2005-2006 Artica Soluciones Tecnologicas S.L, info@artica.es
// Copyright (c) 2004-2006 Raul Mateos Martin, raulofpandora@gmail.com
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

// Load global vars
require("include/config.php");

if (comprueba_login() == 0) {
	$id_usuario =$_SESSION["id_usuario"];
        if (give_acl($id_usuario, 0, "AR")==1) {
		echo "<h2>".$lang_label["events"]."</h2>";
		echo "<h3>".$lang_label["event_statistics"]."<a href='help/".$help_code."/chap5.php#51' target='_help' class='help'>&nbsp;<span>".$lang_label["help"]."</span></a></h3>";
		echo '<img src="reporting/fgraph.php?tipo=total_events" border=0>';
		echo "<br><br>";
		echo '<img src="reporting/fgraph.php?tipo=user_events" border=0>';
		echo "<br><br>";
		echo '<img src="reporting/fgraph.php?tipo=group_events" border=0>';
		echo "<br><br>";
 	} else {
		audit_db($id_user,$REMOTE_ADDR, "ACL Violation","Trying to access event viewer");
		require ("general/noaccess.php");
	}
}
?>