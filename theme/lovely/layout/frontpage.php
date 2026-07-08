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
 * Front page layout for theme_lovely.
 *
 * Forked from theme/boost/layout/drawers.php as shipped in Moodle 5.2.1 (theme_boost
 * 2026042000). Changes from the Boost original:
 *   - builds the hero slider and marketing spot context from theme settings and renders them
 *     through theme_lovely/hero and theme_lovely/marketingspots;
 *   - adds presentation body classes for the front page listing toggles;
 *   - renders theme_lovely/frontpage (a fork of theme_boost/drawers) instead.
 * Everything else deliberately matches the Boost original line for line so upstream layout
 * fixes are easy to re-port.
 *
 * @package   theme_lovely
 * @copyright 2026 frankenphp-moodle
 * @license   http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/behat/lib.php');
require_once($CFG->dirroot . '/course/lib.php');

// Add block button in editing mode.
$addblockbutton = $OUTPUT->addblockbutton();

if (isloggedin()) {
    $courseindexopen = (get_user_preferences('drawer-open-index', true) == true);
    $blockdraweropen = (get_user_preferences('drawer-open-block') == true);
} else {
    $courseindexopen = false;
    $blockdraweropen = false;
}

if (defined('BEHAT_SITE_RUNNING') && get_user_preferences('behat_keep_drawer_closed') != 1) {
    $blockdraweropen = true;
}

$extraclasses = ['uses-drawers', 'lovely-frontpage'];
if ($courseindexopen) {
    $extraclasses[] = 'drawer-open-index';
}

// Lovely: presentation toggles for the standard front page sections (CSS-driven).
$themesettings = $PAGE->theme->settings;
if (!empty($themesettings->frontpagecoursecards)) {
    $extraclasses[] = 'lovely-coursecards';
}
if (!empty($themesettings->frontpagecategorycards)) {
    $extraclasses[] = 'lovely-categorycards';
}
if (!empty($themesettings->frontpagenewsblog)) {
    $extraclasses[] = 'lovely-newsblog';
}

$blockshtml = $OUTPUT->blocks('side-pre');
$hasblocks = (strpos($blockshtml, 'data-block=') !== false || !empty($addblockbutton));
if (!$hasblocks) {
    $blockdraweropen = false;
}
$courseindex = core_course_drawer();
if (!$courseindex) {
    $courseindexopen = false;
}

$bodyattributes = $OUTPUT->body_attributes($extraclasses);
$forceblockdraweropen = $OUTPUT->firstview_fakeblocks();

$secondarynavigation = false;
$overflow = '';
if ($PAGE->has_secondary_navigation()) {
    $tablistnav = $PAGE->has_tablist_secondary_navigation();
    $moremenu = new \core\navigation\output\more_menu($PAGE->secondarynav, 'nav-tabs', true, $tablistnav);
    $secondarynavigation = $moremenu->export_for_template($OUTPUT);
    $overflowdata = $PAGE->secondarynav->get_overflow_menu_data();
    if (!is_null($overflowdata)) {
        $selectmenu = new \core\output\select_menu(
            'tertiarynavigation',
            $overflowdata->urls,
            $overflowdata->selected,
        );
        $selectmenu->set_label($overflowdata->label, $overflowdata->labelattributes);
        $overflow = $selectmenu->export_for_template($OUTPUT);
    }
}

$primary = new core\navigation\output\primary($PAGE);
$renderer = $PAGE->get_renderer('core');
$primarymenu = $primary->export_for_template($renderer);
$buildregionmainsettings = !$PAGE->include_region_main_settings_in_header_actions() && !$PAGE->has_secondary_navigation();
// If the settings menu will be included in the header then don't add it here.
$regionmainsettingsmenu = $buildregionmainsettings ? $OUTPUT->region_main_settings_menu() : false;

$header = $PAGE->activityheader;
$headercontent = $header->export_for_template($renderer);

$coursefullname = ($PAGE->course?->fullname) ? format_string(
    $PAGE->course->fullname,
    true,
    ['context' => context_course::instance($PAGE->course->id), 'escape' => false],
) : '';
$courseurl = $PAGE->course ? new \core\url('/course/view.php', ['id' => $PAGE->course->id]) : null;

// Lovely: hero slider context.
$herohtml = '';
if (!empty($themesettings->sliderenabled)) {
    $slides = [];
    $hasvideo = false;
    for ($i = 1; $i <= 16; $i++) {
        $imageurl = $PAGE->theme->setting_file_url('slideimage' . $i, 'slideimage' . $i);
        if (empty($imageurl)) {
            continue;
        }
        $videourl = $PAGE->theme->setting_file_url('slidevideo' . $i, 'slidevideo' . $i);
        if (!empty($videourl)) {
            $hasvideo = true;
        }
        $heading = trim($themesettings->{'slideheading' . $i} ?? '');
        $caption = trim($themesettings->{'slidecaption' . $i} ?? '');
        $ctalabel = trim($themesettings->{'slidectalabel' . $i} ?? '');
        $ctaurl = trim($themesettings->{'slidectaurl' . $i} ?? '');
        $slides[] = [
            'imageurl' => $imageurl,
            'videourl' => $videourl ?: null,
            'videoposter' => $videourl ? $imageurl : null,
            'heading' => $heading !== '' ? format_string($heading) : null,
            'caption' => $caption !== '' ? format_string($caption) : null,
            'cta' => ($ctalabel !== '' && $ctaurl !== '') ? [
                'label' => format_string($ctalabel),
                'url' => $ctaurl,
            ] : null,
            'hascaption' => $heading !== '' || $caption !== '',
            'first' => false, // Overwritten below.
            'index' => count($slides),
        ];
    }
    if (!empty($slides)) {
        $slides[0]['first'] = true;
    }

    $interval = (int) ($themesettings->sliderinterval ?? 6000);
    if ($interval < 1000) {
        $interval = 6000;
    }

    $transition = $themesettings->slidertransition ?? 'slide';
    $transitionclass = '';
    if ($transition === 'fade') {
        $transitionclass = 'carousel-fade';
    } else if ($transition === 'zoom') {
        $transitionclass = 'carousel-fade lovely-hero-zoom';
    }

    $herocontext = [
        'slides' => $slides,
        'hasslides' => !empty($slides),
        'multiple' => count($slides) > 1,
        'interval' => $interval,
        'transitionclass' => $transitionclass,
        // The pause control covers autoplaying carousels and slide videos (WCAG 2.2.2).
        'hasmedia' => $hasvideo || count($slides) > 1,
        'sitename' => format_string($SITE->fullname, true,
            ['context' => context_course::instance(SITEID), 'escape' => false]),
    ];
    $herohtml = $OUTPUT->render_from_template('theme_lovely/hero', $herocontext);
}

// Lovely: marketing spots context.
$marketinghtml = '';
if (!empty($themesettings->marketingenabled)) {
    $spots = [];
    for ($i = 1; $i <= 4; $i++) {
        $heading = trim($themesettings->{'marketingheading' . $i} ?? '');
        if ($heading === '') {
            continue;
        }
        $icon = trim($themesettings->{'marketingicon' . $i} ?? '');
        if ($icon !== '' && strpos($icon, 'fa-') !== 0) {
            $icon = 'fa-' . $icon;
        }
        $text = trim($themesettings->{'marketingtext' . $i} ?? '');
        $url = trim($themesettings->{'marketingurl' . $i} ?? '');
        $spots[] = [
            'icon' => $icon !== '' ? $icon : null,
            'heading' => format_string($heading),
            'text' => $text !== '' ? format_string($text) : null,
            'url' => $url !== '' ? $url : null,
        ];
    }
    if (!empty($spots)) {
        $marketinghtml = $OUTPUT->render_from_template('theme_lovely/marketingspots', [
            'spots' => $spots,
            'columnclass' => 'col-sm-6 col-lg-' . (12 / max(1, min(4, count($spots)))),
        ]);
    }
}

$templatecontext = [
    'sitename' => format_string($SITE->shortname, true, ['context' => context_course::instance(SITEID), "escape" => false]),
    'coursefullname' => $coursefullname,
    'courseurl' => $courseurl ? $courseurl->out(false) : null,
    'output' => $OUTPUT,
    'sidepreblocks' => $blockshtml,
    'hasblocks' => $hasblocks,
    'bodyattributes' => $bodyattributes,
    'courseindexopen' => $courseindexopen,
    'blockdraweropen' => $blockdraweropen,
    'courseindex' => $courseindex,
    'primarymoremenu' => $primarymenu['moremenu'],
    'secondarymoremenu' => $secondarynavigation ?: false,
    'mobileprimarynav' => $primarymenu['mobileprimarynav'],
    'usermenu' => $primarymenu['user'],
    'langmenu' => $primarymenu['lang'],
    'forceblockdraweropen' => $forceblockdraweropen,
    'regionmainsettingsmenu' => $regionmainsettingsmenu,
    'hasregionmainsettingsmenu' => !empty($regionmainsettingsmenu),
    'overflow' => $overflow,
    'headercontent' => $headercontent,
    'addblockbutton' => $addblockbutton,
    // Lovely additions.
    'lovelyhero' => $herohtml,
    'lovelymarketing' => $marketinghtml,
];

echo $OUTPUT->render_from_template('theme_lovely/frontpage', $templatecontext);
