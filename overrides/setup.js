const sh = require('shelljs');
const path = require('path');

sh.cp('-R', path.join(__dirname, '*'), path.join(__dirname, '..', 'node_modules'))
