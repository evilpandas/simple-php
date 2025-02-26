<?php
  $data = [
   'container' => getenv('HOSTNAME'),
   'timezone' => getenv('TZ'),
   'time' => date('Y-m-d H:i:s'),
   'color' => 'red'
  ];

  echo json_encode($data);
   
?>
