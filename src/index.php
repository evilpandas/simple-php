<?php
  $data = [
   'container' => getenv('HOSTNAME'),
   'timezone' => getenv('TZ'),
   'time' => date('Y-m-d H:i:s'),
   'color' => 'purple'
  ];

  echo json_encode($data);
   
?>
