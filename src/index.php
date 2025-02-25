<?php
  $data = [
   'container' => getenv('HOSTNAME'),
   'timezone' => getenv('TZ'),
   'time' => date('Y-m-d H:i:s'),
   'color' => 'green'
  ];

  echo json_encode($data);
   
?>
