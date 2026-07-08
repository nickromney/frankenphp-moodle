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
 * Settings for theme_lovely.
 *
 * Structured after theme_boost/settings.php (Moodle 5.2): the same tab class and setting
 * types, expanded to the tabs General / Site home / Header / Footer / Colours / Fonts /
 * Login / Advanced.
 *
 * @package    theme_lovely
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

if ($ADMIN->fulltree) {
    // theme_boost_admin_settingspage_tabs is autoloaded from
    // theme/boost/classes/admin_settingspage_tabs.php via Moodle's component classloader.
    $settings = new theme_boost_admin_settingspage_tabs('themesettinglovely', get_string('configtitle', 'theme_lovely'));

    // ---------------------------------------------------------------------------------------
    // General tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_general', get_string('generalsettings', 'theme_lovely'));

    // Preset.
    $name = 'theme_lovely/preset';
    $title = get_string('preset', 'theme_lovely');
    $description = get_string('preset_desc', 'theme_lovely');
    $default = 'default.scss';

    $context = context_system::instance();
    $fs = get_file_storage();
    $files = $fs->get_area_files($context->id, 'theme_lovely', 'preset', 0, 'itemid, filepath, filename', false);

    $choices = [];
    foreach ($files as $file) {
        $choices[$file->get_filename()] = $file->get_filename();
    }
    // The two bundled presets: Lovely's own hand-tuned design, and Boost's unstyled escape hatch.
    $choices['default.scss'] = 'default.scss (' . get_string('pluginname', 'theme_lovely') . ')';
    $choices['plain.scss'] = 'plain.scss (' . get_string('pluginname', 'theme_boost') . ')';

    $setting = new admin_setting_configthemepreset($name, $title, $description, $default, $choices, 'lovely');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    // Preset files.
    $name = 'theme_lovely/presetfiles';
    $title = get_string('presetfiles', 'theme_lovely');
    $description = get_string('presetfiles_desc', 'theme_lovely');
    $setting = new admin_setting_configstoredfile($name, $title, $description, 'preset', 0,
        ['maxfiles' => 20, 'accepted_types' => ['.scss']]);
    $page->add($setting);

    // Page layout: wide vs boxed chrome, with a page background behind the boxed column.
    $page->add(new admin_setting_heading('theme_lovely/pagelayoutheading',
        get_string('pagelayoutheading', 'theme_lovely'), get_string('pagelayoutheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configselect('theme_lovely/pagelayoutstyle',
        get_string('pagelayoutstyle', 'theme_lovely'), get_string('pagelayoutstyle_desc', 'theme_lovely'),
        'wide', [
            'wide' => get_string('pagelayoutwide', 'theme_lovely'),
            'boxed' => get_string('pagelayoutboxed', 'theme_lovely'),
        ]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcolourpicker('theme_lovely/pagebackgroundcolor',
        get_string('pagebackgroundcolor', 'theme_lovely'), get_string('pagebackgroundcolor_desc', 'theme_lovely'), '');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configstoredfile('theme_lovely/pagebackgroundimage',
        get_string('pagebackgroundimage', 'theme_lovely'), get_string('pagebackgroundimage_desc', 'theme_lovely'),
        'pagebackgroundimage', 0, ['accepted_types' => ['web_image']]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/pagebackgroundtint',
        get_string('pagebackgroundtint', 'theme_lovely'), get_string('pagebackgroundtint_desc', 'theme_lovely'),
        '0.35', [
            '0' => get_string('tintnone', 'theme_lovely'),
            '0.2' => get_string('tintlight', 'theme_lovely'),
            '0.35' => get_string('tintmedium', 'theme_lovely'),
            '0.6' => get_string('tintstrong', 'theme_lovely'),
        ]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $settings->add($page);

    // ---------------------------------------------------------------------------------------
    // Site home tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_sitehome', get_string('sitehomesettings', 'theme_lovely'));

    // Hero slider.
    $page->add(new admin_setting_heading('theme_lovely/heroheading',
        get_string('heroheading', 'theme_lovely'), get_string('heroheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configcheckbox('theme_lovely/sliderenabled',
        get_string('sliderenabled', 'theme_lovely'), get_string('sliderenabled_desc', 'theme_lovely'), 0);
    $page->add($setting);

    $setting = new admin_setting_configtext('theme_lovely/sliderinterval',
        get_string('sliderinterval', 'theme_lovely'), get_string('sliderinterval_desc', 'theme_lovely'),
        '6000', PARAM_INT);
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/sliderheight',
        get_string('sliderheight', 'theme_lovely'), get_string('sliderheight_desc', 'theme_lovely'),
        '24rem', [
            '18rem' => get_string('sliderheightcompact', 'theme_lovely'),
            '24rem' => get_string('sliderheightstandard', 'theme_lovely'),
            '32rem' => get_string('sliderheighttall', 'theme_lovely'),
            '42rem' => get_string('sliderheightgrand', 'theme_lovely'),
        ]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/sliderhidecaptionsmobile',
        get_string('sliderhidecaptionsmobile', 'theme_lovely'),
        get_string('sliderhidecaptionsmobile_desc', 'theme_lovely'), 0);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/slidertransition',
        get_string('slidertransition', 'theme_lovely'), get_string('slidertransition_desc', 'theme_lovely'),
        'slide', [
            'slide' => get_string('transitionslide', 'theme_lovely'),
            'fade' => get_string('transitionfade', 'theme_lovely'),
            'zoom' => get_string('transitionzoom', 'theme_lovely'),
        ]);
    $page->add($setting);

    for ($i = 1; $i <= 16; $i++) {
        $setting = new admin_setting_configstoredfile('theme_lovely/slideimage' . $i,
            get_string('slideimage', 'theme_lovely', $i), get_string('slideimage_desc', 'theme_lovely'),
            'slideimage' . $i, 0, ['accepted_types' => ['web_image']]);
        $setting->set_updatedcallback('theme_reset_all_caches');
        $page->add($setting);

        $setting = new admin_setting_configstoredfile('theme_lovely/slidevideo' . $i,
            get_string('slidevideo', 'theme_lovely', $i), get_string('slidevideo_desc', 'theme_lovely'),
            'slidevideo' . $i, 0, ['accepted_types' => ['.mp4', '.webm']]);
        $setting->set_updatedcallback('theme_reset_all_caches');
        $page->add($setting);

        $setting = new admin_setting_configtext('theme_lovely/slideheading' . $i,
            get_string('slideheading', 'theme_lovely', $i), get_string('slideheading_desc', 'theme_lovely'),
            '', PARAM_TEXT);
        $page->add($setting);

        $setting = new admin_setting_configtextarea('theme_lovely/slidecaption' . $i,
            get_string('slidecaption', 'theme_lovely', $i), get_string('slidecaption_desc', 'theme_lovely'),
            '', PARAM_TEXT);
        $page->add($setting);

        $setting = new admin_setting_configtext('theme_lovely/slidectalabel' . $i,
            get_string('slidectalabel', 'theme_lovely', $i), get_string('slidectalabel_desc', 'theme_lovely'),
            '', PARAM_TEXT);
        $page->add($setting);

        $setting = new admin_setting_configtext('theme_lovely/slidectaurl' . $i,
            get_string('slidectaurl', 'theme_lovely', $i), get_string('slidectaurl_desc', 'theme_lovely'),
            '', PARAM_URL);
        $page->add($setting);
    }

    // Marketing spots.
    $page->add(new admin_setting_heading('theme_lovely/marketingheading',
        get_string('marketingheading', 'theme_lovely'), get_string('marketingheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configcheckbox('theme_lovely/marketingenabled',
        get_string('marketingenabled', 'theme_lovely'), get_string('marketingenabled_desc', 'theme_lovely'), 0);
    $page->add($setting);

    for ($i = 1; $i <= 4; $i++) {
        $setting = new admin_setting_configtext('theme_lovely/marketingicon' . $i,
            get_string('marketingicon', 'theme_lovely', $i), get_string('marketingicon_desc', 'theme_lovely'),
            '', PARAM_TEXT);
        $page->add($setting);

        $setting = new admin_setting_configtext('theme_lovely/marketingheading' . $i,
            get_string('marketingheadingsetting', 'theme_lovely', $i),
            get_string('marketingheadingsetting_desc', 'theme_lovely'), '', PARAM_TEXT);
        $page->add($setting);

        $setting = new admin_setting_configtextarea('theme_lovely/marketingtext' . $i,
            get_string('marketingtext', 'theme_lovely', $i), get_string('marketingtext_desc', 'theme_lovely'),
            '', PARAM_TEXT);
        $page->add($setting);

        $setting = new admin_setting_configtext('theme_lovely/marketingurl' . $i,
            get_string('marketingurl', 'theme_lovely', $i), get_string('marketingurl_desc', 'theme_lovely'),
            '', PARAM_URL);
        $page->add($setting);
    }

    // Course and category listing presentation.
    $page->add(new admin_setting_heading('theme_lovely/frontpagelistingsheading',
        get_string('frontpagelistingsheading', 'theme_lovely'),
        get_string('frontpagelistingsheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configcheckbox('theme_lovely/frontpagecoursecards',
        get_string('frontpagecoursecards', 'theme_lovely'), get_string('frontpagecoursecards_desc', 'theme_lovely'), 1);
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/frontpagecategorycards',
        get_string('frontpagecategorycards', 'theme_lovely'),
        get_string('frontpagecategorycards_desc', 'theme_lovely'), 1);
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/frontpagenewsblog',
        get_string('frontpagenewsblog', 'theme_lovely'), get_string('frontpagenewsblog_desc', 'theme_lovely'), 1);
    $page->add($setting);

    // Dashboard.
    $page->add(new admin_setting_heading('theme_lovely/dashboardheading',
        get_string('dashboardheading', 'theme_lovely'), get_string('dashboardheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configstoredfile('theme_lovely/dashboardbanner',
        get_string('dashboardbanner', 'theme_lovely'), get_string('dashboardbanner_desc', 'theme_lovely'),
        'dashboardbanner', 0, ['accepted_types' => ['web_image']]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    // Courses.
    $page->add(new admin_setting_heading('theme_lovely/coursesheading',
        get_string('coursesheading', 'theme_lovely'), get_string('coursesheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configcheckbox('theme_lovely/courseheaderbanner',
        get_string('courseheaderbanner', 'theme_lovely'), get_string('courseheaderbanner_desc', 'theme_lovely'), 0);
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/activityiconstyle',
        get_string('activityiconstyle', 'theme_lovely'), get_string('activityiconstyle_desc', 'theme_lovely'),
        'tiles', [
            'tiles' => get_string('iconstiles', 'theme_lovely'),
            'circles' => get_string('iconscircles', 'theme_lovely'),
            'mono' => get_string('iconsmono', 'theme_lovely'),
        ]);
    $page->add($setting);

    $settings->add($page);

    // ---------------------------------------------------------------------------------------
    // Header tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_header', get_string('headersettings', 'theme_lovely'));

    $page->add(new admin_setting_heading('theme_lovely/topbarheading',
        get_string('topbarheading', 'theme_lovely'), get_string('topbarheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configcheckbox('theme_lovely/topbarenabled',
        get_string('topbarenabled', 'theme_lovely'), get_string('topbarenabled_desc', 'theme_lovely'), 0);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configtext('theme_lovely/topbarphone',
        get_string('topbarphone', 'theme_lovely'), get_string('topbarphone_desc', 'theme_lovely'), '', PARAM_TEXT);
    $page->add($setting);

    $setting = new admin_setting_configtext('theme_lovely/topbaremail',
        get_string('topbaremail', 'theme_lovely'), get_string('topbaremail_desc', 'theme_lovely'), '', PARAM_TEXT);
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/topbarshowlogin',
        get_string('topbarshowlogin', 'theme_lovely'), get_string('topbarshowlogin_desc', 'theme_lovely'), 1);
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/topbarshowsocial',
        get_string('topbarshowsocial', 'theme_lovely'), get_string('topbarshowsocial_desc', 'theme_lovely'), 0);
    $page->add($setting);

    $page->add(new admin_setting_heading('theme_lovely/navbarheading',
        get_string('navbarheading', 'theme_lovely'), get_string('navbarheading_desc', 'theme_lovely')));

    $setting = new admin_setting_configselect('theme_lovely/headerlayout',
        get_string('headerlayout', 'theme_lovely'), get_string('headerlayout_desc', 'theme_lovely'),
        'default', [
            'default' => get_string('headerlayoutdefault', 'theme_lovely'),
            'centered' => get_string('headerlayoutcentered', 'theme_lovely'),
            'compact' => get_string('headerlayoutcompact', 'theme_lovely'),
        ]);
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/stickyheader',
        get_string('stickyheader', 'theme_lovely'), get_string('stickyheader_desc', 'theme_lovely'), 1);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configtext('theme_lovely/logoheight',
        get_string('logoheight', 'theme_lovely'), get_string('logoheight_desc', 'theme_lovely'), '', PARAM_TEXT);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $settings->add($page);

    // ---------------------------------------------------------------------------------------
    // Footer tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_footer', get_string('footersettings', 'theme_lovely'));

    $page->add(new admin_setting_heading('theme_lovely/footercolumnsheading',
        get_string('footercolumnsheading', 'theme_lovely'), get_string('footercolumnsheading_desc', 'theme_lovely')));

    for ($i = 1; $i <= 4; $i++) {
        $setting = new admin_setting_confightmleditor('theme_lovely/footercolumn' . $i,
            get_string('footercolumn', 'theme_lovely', $i), get_string('footercolumn_desc', 'theme_lovely', $i),
            '', PARAM_RAW);
        $page->add($setting);
    }

    $page->add(new admin_setting_heading('theme_lovely/socialheading',
        get_string('socialheading', 'theme_lovely'), get_string('socialheading_desc', 'theme_lovely')));

    $socialnetworks = ['facebook', 'x', 'instagram', 'linkedin', 'youtube', 'github', 'mastodon', 'website'];
    foreach ($socialnetworks as $network) {
        $setting = new admin_setting_configtext('theme_lovely/social' . $network,
            get_string('social' . $network, 'theme_lovely'), get_string('socialurl_desc', 'theme_lovely'),
            '', PARAM_URL);
        $page->add($setting);
    }

    $page->add(new admin_setting_heading('theme_lovely/footnoteheading',
        get_string('footnoteheading', 'theme_lovely'), get_string('footnoteheading_desc', 'theme_lovely')));

    $setting = new admin_setting_confightmleditor('theme_lovely/footnote',
        get_string('footnote', 'theme_lovely'), get_string('footnote_desc', 'theme_lovely'), '', PARAM_RAW);
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/scrolltotopenabled',
        get_string('scrolltotopenabled', 'theme_lovely'), get_string('scrolltotopenabled_desc', 'theme_lovely'), 1);
    $page->add($setting);

    $settings->add($page);

    // ---------------------------------------------------------------------------------------
    // Colours tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_colours', get_string('colourssettings', 'theme_lovely'));

    // Primary brand colour. Feeds $primary via theme_lovely_get_pre_scss().
    $setting = new admin_setting_configcolourpicker('theme_lovely/brandcolor',
        get_string('brandcolor', 'theme_lovely'), get_string('brandcolor_desc', 'theme_lovely'), '#1B5A6B');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    // Secondary / accent colour. Feeds $lovely-accent; used sparingly rather than as
    // Bootstrap's neutral "secondary".
    $setting = new admin_setting_configcolourpicker('theme_lovely/secondarycolor',
        get_string('secondarycolor', 'theme_lovely'), get_string('secondarycolor_desc', 'theme_lovely'), '#B14A24');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcolourpicker('theme_lovely/headerbgcolor',
        get_string('headerbgcolor', 'theme_lovely'), get_string('headerbgcolor_desc', 'theme_lovely'), '');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcolourpicker('theme_lovely/footerbgcolor',
        get_string('footerbgcolor', 'theme_lovely'), get_string('footerbgcolor_desc', 'theme_lovely'), '');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcolourpicker('theme_lovely/drawerbgcolor',
        get_string('drawerbgcolor', 'theme_lovely'), get_string('drawerbgcolor_desc', 'theme_lovely'), '');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcolourpicker('theme_lovely/linkcolor',
        get_string('linkcolor', 'theme_lovely'), get_string('linkcolor_desc', 'theme_lovely'), '');
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/buttonradius',
        get_string('buttonradius', 'theme_lovely'), get_string('buttonradius_desc', 'theme_lovely'),
        '0.5rem', [
            '0' => get_string('buttonradiussquare', 'theme_lovely'),
            '0.25rem' => get_string('buttonradiussubtle', 'theme_lovely'),
            '0.5rem' => get_string('buttonradiussoft', 'theme_lovely'),
            '0.75rem' => get_string('buttonradiusround', 'theme_lovely'),
            '2rem' => get_string('buttonradiuspill', 'theme_lovely'),
        ]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/basefontsize',
        get_string('basefontsize', 'theme_lovely'), get_string('basefontsize_desc', 'theme_lovely'),
        '1rem', [
            '0.9375rem' => '15px',
            '1rem' => '16px',
            '1.0625rem' => '17px',
            '1.125rem' => '18px',
        ]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/darkmode',
        get_string('darkmode', 'theme_lovely'), get_string('darkmode_desc', 'theme_lovely'), 0);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $settings->add($page);

    // ---------------------------------------------------------------------------------------
    // Fonts tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_fonts', get_string('fontssettings', 'theme_lovely'));

    $page->add(new admin_setting_heading('theme_lovely/fontsheading',
        get_string('fontsheading', 'theme_lovely'), get_string('fontsheading_desc', 'theme_lovely')));

    $fontchoices = [
        'system' => get_string('fontsystem', 'theme_lovely'),
        'inter' => get_string('fontinter', 'theme_lovely'),
        'sourcesans' => get_string('fontsourcesans', 'theme_lovely'),
        'lora' => get_string('fontlora', 'theme_lovely'),
        'custom' => get_string('fontcustom', 'theme_lovely'),
    ];

    $setting = new admin_setting_configselect('theme_lovely/bodyfont',
        get_string('bodyfont', 'theme_lovely'), get_string('bodyfont_desc', 'theme_lovely'),
        'system', $fontchoices);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/headingfont',
        get_string('headingfont', 'theme_lovely'), get_string('headingfont_desc', 'theme_lovely'),
        'sameasbody', ['sameasbody' => get_string('fontsameasbody', 'theme_lovely')] + $fontchoices);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configstoredfile('theme_lovely/bodyfontfile',
        get_string('bodyfontfile', 'theme_lovely'), get_string('bodyfontfile_desc', 'theme_lovely'),
        'bodyfontfile', 0, ['accepted_types' => ['.woff2', '.woff', '.ttf']]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configstoredfile('theme_lovely/headingfontfile',
        get_string('headingfontfile', 'theme_lovely'), get_string('headingfontfile_desc', 'theme_lovely'),
        'headingfontfile', 0, ['accepted_types' => ['.woff2', '.woff', '.ttf']]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $settings->add($page);

    // ---------------------------------------------------------------------------------------
    // Login tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_login', get_string('loginsettings', 'theme_lovely'));

    $setting = new admin_setting_configstoredfile('theme_lovely/loginbackgroundimage',
        get_string('loginbackgroundimage', 'theme_lovely'), get_string('loginbackgroundimage_desc', 'theme_lovely'),
        'loginbackgroundimage', 0, ['accepted_types' => ['web_image']]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configstoredfile('theme_lovely/loginbackgroundimage2',
        get_string('loginbackgroundimage2', 'theme_lovely'), get_string('loginbackgroundimage2_desc', 'theme_lovely'),
        'loginbackgroundimage2', 0, ['accepted_types' => ['web_image']]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configstoredfile('theme_lovely/loginbackgroundimage3',
        get_string('loginbackgroundimage3', 'theme_lovely'), get_string('loginbackgroundimage3_desc', 'theme_lovely'),
        'loginbackgroundimage3', 0, ['accepted_types' => ['web_image']]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configselect('theme_lovely/loginposition',
        get_string('loginposition', 'theme_lovely'), get_string('loginposition_desc', 'theme_lovely'),
        'right', [
            'right' => get_string('loginpositionright', 'theme_lovely'),
            'left' => get_string('loginpositionleft', 'theme_lovely'),
            'centered' => get_string('loginpositioncentered', 'theme_lovely'),
        ]);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configstoredfile('theme_lovely/loginbackgroundvideo',
        get_string('loginbackgroundvideo', 'theme_lovely'), get_string('loginbackgroundvideo_desc', 'theme_lovely'),
        'loginbackgroundvideo', 0, ['accepted_types' => ['.mp4', '.webm']]);
    // The extra-SCSS callback reads this setting (panel transparency behind the video), so the
    // compiled theme CSS must be invalidated when it changes, same as the image settings above.
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $setting = new admin_setting_configcheckbox('theme_lovely/loginmodalenabled',
        get_string('loginmodalenabled', 'theme_lovely'), get_string('loginmodalenabled_desc', 'theme_lovely'), 0);
    $page->add($setting);

    $settings->add($page);

    // ---------------------------------------------------------------------------------------
    // Advanced tab.
    // ---------------------------------------------------------------------------------------
    $page = new admin_settingpage('theme_lovely_advanced', get_string('advancedsettings', 'theme_lovely'));

    // Raw SCSS injected before the preset compiles (mainly for variable overrides).
    $setting = new admin_setting_scsscode('theme_lovely/scsspre',
        get_string('rawscsspre', 'theme_lovely'), get_string('rawscsspre_desc', 'theme_lovely'), '', PARAM_RAW);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    // Raw SCSS injected after the preset compiles.
    $setting = new admin_setting_scsscode('theme_lovely/scss',
        get_string('rawscss', 'theme_lovely'), get_string('rawscss_desc', 'theme_lovely'), '', PARAM_RAW);
    $setting->set_updatedcallback('theme_reset_all_caches');
    $page->add($setting);

    $settings->add($page);
}
