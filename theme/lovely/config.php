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
 * Lovely config.
 *
 * A calm, modern Boost child theme. Structured directly after theme_boost's own config.php
 * (theme/boost/config.php in Moodle 5.2), keeping every Boost behaviour that isn't explicitly
 * overridden here: page layouts, the drawer-based course index, the split-screen login page,
 * and the FontAwesome icon system.
 *
 * @package    theme_lovely
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

require_once(__DIR__ . '/lib.php');

$THEME->name = 'lovely';
$THEME->parents = ['boost'];
$THEME->sheets = [];
$THEME->editor_sheets = [];

// Note: $THEME->editor_scss is intentionally left unset. theme_config falls back up the parent
// chain when it's empty, which correctly resolves to theme_boost's own scss/editor.scss.

$THEME->usefallback = true;

$THEME->scss = function($theme) {
    return theme_lovely_get_main_scss_content($theme);
};
$THEME->prescsscallback = 'theme_lovely_get_pre_scss';
$THEME->extrascsscallback = 'theme_lovely_get_extra_scss';

// Moodle merges parent theme layouts automatically and per-layout (child entries win), so
// only the front page layout is overridden here - every other Boost drawer/login/embedded
// layout is inherited unchanged. layout/frontpage.php is a documented fork of Boost 5.2's
// drawers.php that adds the hero slider and marketing spot sections.
$THEME->layouts = [
    // The site home page.
    'frontpage' => [
        'file' => 'frontpage.php',
        'regions' => ['side-pre'],
        'defaultregion' => 'side-pre',
        'options' => ['nonavbar' => true],
    ],
];

// The properties below are not automatically inherited from the parent theme by Moodle's theme
// engine (only $THEME->layouts and a couple of SCSS-related properties are), so they are copied
// here to match theme_boost/config.php in Moodle 5.2 and keep Lovely behaving like Boost.
$THEME->enable_dock = false;
$THEME->yuicssmodules = [];
$THEME->rendererfactory = 'theme_overridden_renderer_factory';
$THEME->requiredblocks = '';
$THEME->addblockposition = BLOCK_ADDBLOCK_POSITION_FLATNAV;
$THEME->iconsystem = \core\output\icon_system::FONTAWESOME;
$THEME->haseditswitch = true;
$THEME->usescourseindex = true;
$THEME->activityheaderconfig = [
    'notitle' => true,
];
