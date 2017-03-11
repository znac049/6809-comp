#!/usr/bin/php
<?php

if (count($argv) != 2) {
   exit(1);
}

$lines = file($argv[1]);
foreach ($lines as $line) {
  $l = trim($line);

  if (substr($l,0,2) == 'S1') {
    echo $l . "\r";
    usleep(75000);
  }
}