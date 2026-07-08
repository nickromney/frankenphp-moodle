<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

/**
 * Version details for theme_lovely.
 *
 * A calm, modern Boost child theme.
 *
 * @package    theme_lovely
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

// Matches theme_boost's own $plugin->requires for Moodle 5.2 (stable502), read from the
// built image's /app/public/public/theme/boost/version.php so this child theme never claims
// compatibility it hasn't actually been checked against.
$plugin->component = 'theme_lovely';
$plugin->version   = 2026070813;
$plugin->requires  = 2026042000;
$plugin->supported = [502, 502];
$plugin->release   = '1.2.2 for Moodle 5.2';
$plugin->maturity  = MATURITY_STABLE;
$plugin->dependencies = [
    'theme_boost' => 2026042000,
];
