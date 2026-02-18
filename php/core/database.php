<?php

$server = "localhost";
$user = "root";
$password = "";
$database = "football_tracker";

$conn = mysqli_connect($server, $user, $password, $database);
$response = array();

// Check connection
if (mysqli_connect_errno()) {
    $response["error"] = true;
    $response["error_msg"] = "Failed to connect to MySQL: " . mysqli_connect_error();
    echo json_encode($response);
    exit;
}
?> 