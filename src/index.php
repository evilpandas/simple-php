<?php
  $data = [
   'container' => getenv('HOSTNAME'),
   'timezone' => getenv('TZ'),
   'time' => date('Y-m-d H:i:s')
  ];
  
  echo json_encode($data);
   
?>
