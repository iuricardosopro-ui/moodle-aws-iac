<?php
// Minimal config.php driven entirely by environment variables injected by
// the ECS task definition (see terraform/modules/ecs/main.tf). No secret
// ever gets baked into the image or committed to this repository.

$CFG = new stdClass();

$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = getenv('MOODLE_DATABASE_HOST');
$CFG->dbname    = getenv('MOODLE_DATABASE_NAME');
$CFG->dbuser    = getenv('MOODLE_DATABASE_USER');
$CFG->dbpass    = getenv('MOODLE_DATABASE_PASSWORD');
$CFG->prefix    = 'mdl_';
$CFG->dboptions = [
    'dbpersist' => false,
    'dbport'    => '',
    'dbsocket'  => '',
];

$CFG->wwwroot   = getenv('MOODLE_WWWROOT') ?: 'http://localhost:8080';
$CFG->dataroot  = '/var/www/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 0777;

require_once __DIR__ . '/lib/setup.php';
