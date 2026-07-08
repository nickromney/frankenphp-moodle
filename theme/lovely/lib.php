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
 * Theme functions for theme_lovely.
 *
 * Follows the same shape as theme_boost/lib.php (Moodle 5.2): a preset-based
 * get_main_scss_content(), a get_pre_scss() that turns admin settings into SCSS variables
 * injected before the preset compiles, and a get_extra_scss() that appends generated CSS
 * (login backgrounds, fonts, dashboard banner, hero sizing) after it.
 *
 * @package    theme_lovely
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

/**
 * Returns the main SCSS content to be compiled.
 *
 * Mirrors theme_boost_get_main_scss_content(): the "default.scss" and "plain.scss" preset
 * choices are bundled files (Lovely's own hand-tuned preset, and Boost's unstyled escape
 * hatch respectively), anything else is looked up as an uploaded preset file.
 *
 * @param theme_config $theme The theme config object.
 * @return string
 */
function theme_lovely_get_main_scss_content($theme) {
    global $CFG;

    $scss = '';
    $filename = !empty($theme->settings->preset) ? $theme->settings->preset : 'default.scss';
    $fs = get_file_storage();
    $context = context_system::instance();

    if ($filename === 'default.scss') {
        $scss .= file_get_contents($CFG->dirroot . '/theme/lovely/scss/preset/default.scss');
    } else if ($filename === 'plain.scss') {
        // Escape hatch back to unstyled Boost, exactly as shipped by theme_boost itself.
        $scss .= file_get_contents($CFG->dirroot . '/theme/boost/scss/preset/plain.scss');
    } else if ($presetfile = $fs->get_file($context->id, 'theme_lovely', 'preset', 0, '/', $filename)) {
        $scss .= $presetfile->get_content();
    } else {
        // Safety fallback - e.g. a preset file was deleted after being selected.
        $scss .= file_get_contents($CFG->dirroot . '/theme/lovely/scss/preset/default.scss');
    }

    return $scss;
}

/**
 * Map a bundled font choice to a CSS font-family stack.
 *
 * @param string $choice One of inter|sourcesans|lora|custom.
 * @param string $customfamily Family name to use for the "custom" choice.
 * @return string|null The font-family value, or null for the system stack / unknown choices.
 */
function theme_lovely_font_family(string $choice, string $customfamily): ?string {
    $fallback = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, '
        . '"Helvetica Neue", Arial, "Noto Sans", sans-serif';
    switch ($choice) {
        case 'inter':
            return '"Inter", ' . $fallback;
        case 'sourcesans':
            return '"Source Sans 3", ' . $fallback;
        case 'lora':
            return '"Lora", Georgia, "Times New Roman", serif';
        case 'custom':
            return '"' . $customfamily . '", ' . $fallback;
        default:
            return null;
    }
}

/**
 * Whether a CSS hex colour is light (relative luminance above 0.5).
 *
 * Used to keep navbar text readable whatever header background an admin picks.
 *
 * @param string $hex '#rgb' or '#rrggbb'.
 * @return bool True when light; false when dark or unparseable.
 */
function theme_lovely_color_is_light(string $hex): bool {
    $hex = ltrim(trim($hex), '#');
    if (strlen($hex) === 3) {
        $hex = $hex[0] . $hex[0] . $hex[1] . $hex[1] . $hex[2] . $hex[2];
    }
    if (!preg_match('/^[0-9a-fA-F]{6}$/', $hex)) {
        return false;
    }
    $channels = [];
    foreach (str_split($hex, 2) as $part) {
        $c = hexdec($part) / 255;
        $channels[] = ($c <= 0.03928) ? $c / 12.92 : pow(($c + 0.055) / 1.055, 2.4);
    }
    $luminance = 0.2126 * $channels[0] + 0.7152 * $channels[1] + 0.0722 * $channels[2];
    return $luminance > 0.5;
}

/**
 * Returns SCSS to prepend, injected before the main preset content is compiled.
 *
 * Because this output comes first, and every variable it touches is declared with `!default`
 * further down the pipeline (preset, Bootstrap, Boost), plain assignments here win without
 * forking the preset. Ordering inside this function matters: the dark-mode block runs first
 * so that explicit colour picker values can still override it.
 *
 * @param theme_config $theme The theme config object.
 * @return string
 */
function theme_lovely_get_pre_scss($theme) {
    $scss = '';

    $darkmode = !empty($theme->settings->darkmode);
    if ($darkmode) {
        // Dark palette. Every combination checked for WCAG AA (4.5:1 text on both the page
        // background #161D20 and the raised surface #1F282C; 3:1 for input borders).
        $scss .= '$lovely-darkmode: true;' . "\n";
        $scss .= '$lovely-body-bg: #161D20;' . "\n";
        $scss .= '$lovely-gray-white: #1F282C;' . "\n"; // Card/surface colour.
        $scss .= '$lovely-gray-100: #242E33;' . "\n";
        $scss .= '$lovely-gray-200: #35424A;' . "\n";
        $scss .= '$lovely-gray-300: #435159;' . "\n";
        $scss .= '$lovely-gray-400: #5D6E77;' . "\n";
        $scss .= '$lovely-gray-500: #7C8F99;' . "\n";  // Input borders: 4.5:1 on bg, 4.4:1 on surface.
        $scss .= '$lovely-gray-600: #9FB0B8;' . "\n";  // Muted text: 7.6:1 on bg.
        $scss .= '$lovely-gray-700: #C3CFD5;' . "\n";
        $scss .= '$lovely-gray-800: #DCE4E8;' . "\n";
        $scss .= '$lovely-gray-900: #EFF3F5;' . "\n";  // Body text: 15.3:1 on bg.
        $scss .= '$lovely-primary-900: #D6E7EC;' . "\n"; // Headings flip to light.
        $scss .= '$lovely-primary-100: #1E3A44;' . "\n"; // Tint backgrounds flip to dark.
        $scss .= '$lovely-primary-50: #1A2E36;' . "\n";
        $scss .= '$lovely-success: #5FBF96;' . "\n";   // 7.6:1 on bg.
        $scss .= '$lovely-info: #6BBAD3;' . "\n";      // 7.8:1 on bg.
        $scss .= '$lovely-warning: #D9A45B;' . "\n";   // 7.7:1 on bg.
        $scss .= '$lovely-danger: #F08A84;' . "\n";    // 7.1:1 on bg.
        $scss .= '$dark: #11181C;' . "\n";
        // Keep shadows dark rather than letting them derive from the flipped primary-900.
        $scss .= '$box-shadow-sm: 0 1px 2px rgba(#000, 0.35);' . "\n";
        $scss .= '$box-shadow: 0 4px 12px rgba(#000, 0.45), 0 2px 4px rgba(#000, 0.3);' . "\n";
        $scss .= '$box-shadow-lg: 0 20px 40px rgba(#000, 0.55), 0 8px 20px rgba(#000, 0.35);' . "\n";
    }

    $configurable = [
        // Config key => [SCSS variable name, ...].
        'brandcolor' => ['primary'],
        'secondarycolor' => ['lovely-accent'],
        'headerbgcolor' => ['lovely-navbar-bg'],
        'footerbgcolor' => ['lovely-footer-bg'],
        // Feeds both Boost's own drawer variable (scss/moodle/drawer.scss) and the theme's.
        'drawerbgcolor' => ['drawer-bg-color', 'lovely-drawer-bg'],
        'linkcolor' => ['link-color'],
        'buttonradius' => ['btn-border-radius'],
        'basefontsize' => ['font-size-base'],
    ];

    foreach ($configurable as $configkey => $targets) {
        $value = $theme->settings->{$configkey} ?? null;
        // Not empty(): the "Square" button radius is the string '0', which empty() would drop.
        if ($value === null || $value === '') {
            continue;
        }
        // In dark mode the light-palette defaults for the two brand pickers would fail
        // contrast on the dark background, so unchanged defaults get dark-tuned substitutes
        // (an explicitly changed picker is respected as-is).
        if ($darkmode && $configkey === 'brandcolor' && strtoupper($value) === '#1B5A6B') {
            $value = '#55AECB'; // 6.8:1 on the dark background.
        }
        if ($darkmode && $configkey === 'secondarycolor' && strtoupper($value) === '#B14A24') {
            $value = '#E08B63'; // 6.5:1 on the dark background.
        }
        foreach ($targets as $target) {
            $scss .= '$' . $target . ': ' . $value . ";\n";
        }
    }

    // Navbar text colour follows the effective header background: a light custom header
    // background flips the bar's text/icons to dark ink (verified visually - white text on a
    // light bar is exactly the bug that shipped once).
    $headerbg = $theme->settings->headerbgcolor ?? '';
    if (!empty($headerbg) && theme_lovely_color_is_light($headerbg)) {
        $scss .= '$lovely-navbar-fg: #1f2a2e;' . "\n";
    }

    // Fonts. Bundled fonts are declared via @font-face in theme_lovely_get_extra_scss();
    // here we only set the family variables (they must exist before Bootstrap compiles).
    $bodyfont = $theme->settings->bodyfont ?? 'system';
    $bodyfamily = theme_lovely_font_family($bodyfont, 'Lovely Custom Body');
    if ($bodyfamily !== null && ($bodyfont !== 'custom' || $theme->setting_file_url('bodyfontfile', 'bodyfontfile'))) {
        $scss .= '$font-family-sans-serif: ' . $bodyfamily . ";\n";
    }

    $headingfont = $theme->settings->headingfont ?? 'sameasbody';
    if ($headingfont !== 'sameasbody') {
        $headingfamily = theme_lovely_font_family($headingfont, 'Lovely Custom Heading');
        if ($headingfamily !== null
                && ($headingfont !== 'custom' || $theme->setting_file_url('headingfontfile', 'headingfontfile'))) {
            $scss .= '$headings-font-family: ' . $headingfamily . ";\n";
        }
    }

    // Behat needs animations/transitions disabled for reliable UI tests, same as Boost.
    if (defined('BEHAT_SITE_RUNNING')) {
        $scss .= "\$behatsite: true;\n";
    }

    if (!empty($theme->settings->scsspre)) {
        $scss .= $theme->settings->scsspre;
    }

    return $scss;
}

/**
 * Build the @font-face rules for the configured fonts.
 *
 * Bundled fonts are served by Moodle's theme font endpoint via the `[[font:theme|file]]`
 * placeholder (resolved to theme/lovely/fonts/<file> at CSS post-processing time - no
 * external requests, ever). Custom uploads are served through theme_lovely_pluginfile().
 *
 * @param theme_config $theme The theme config object.
 * @return string CSS.
 */
function theme_lovely_font_faces($theme): string {
    $css = '';

    $bundled = [
        'inter' => [
            'family' => 'Inter',
            'roman' => 'InterVariable.woff2',
            'italic' => 'InterVariable-Italic.woff2',
        ],
        'sourcesans' => [
            'family' => 'Source Sans 3',
            'roman' => 'SourceSans3-Variable.woff2',
            'italic' => 'SourceSans3-Variable-Italic.woff2',
        ],
        'lora' => [
            'family' => 'Lora',
            'roman' => 'Lora-Variable.woff2',
            'italic' => 'Lora-Variable-Italic.woff2',
        ],
    ];

    $wanted = [];
    $bodyfont = $theme->settings->bodyfont ?? 'system';
    $headingfont = $theme->settings->headingfont ?? 'sameasbody';
    if (isset($bundled[$bodyfont])) {
        $wanted[$bodyfont] = true;
    }
    if (isset($bundled[$headingfont])) {
        $wanted[$headingfont] = true;
    }

    foreach (array_keys($wanted) as $key) {
        $font = $bundled[$key];
        $css .= '@font-face { font-family: "' . $font['family'] . '";';
        $css .= ' src: url([[font:theme|' . $font['roman'] . ']]) format("woff2-variations");';
        $css .= ' font-weight: 100 900; font-style: normal; font-display: swap; }' . "\n";
        $css .= '@font-face { font-family: "' . $font['family'] . '";';
        $css .= ' src: url([[font:theme|' . $font['italic'] . ']]) format("woff2-variations");';
        $css .= ' font-weight: 100 900; font-style: italic; font-display: swap; }' . "\n";
    }

    // Custom uploads.
    if ($bodyfont === 'custom') {
        $url = $theme->setting_file_url('bodyfontfile', 'bodyfontfile');
        if (!empty($url)) {
            $css .= '@font-face { font-family: "Lovely Custom Body";';
            $css .= " src: url('" . $url . "');";
            $css .= ' font-display: swap; }' . "\n";
        }
    }
    if ($headingfont === 'custom') {
        $url = $theme->setting_file_url('headingfontfile', 'headingfontfile');
        if (!empty($url)) {
            $css .= '@font-face { font-family: "Lovely Custom Heading";';
            $css .= " src: url('" . $url . "');";
            $css .= ' font-display: swap; }' . "\n";
        }
    }

    return $css;
}

/**
 * Build the login page background CSS (single image, slideshow, or brand gradient).
 *
 * IMPORTANT: theme_config::get_extra_scss_code() calls every parent theme's extrascsscallback
 * *before* this one (see lib/classes/output/theme_config.php), so theme_boost_get_extra_scss()
 * always runs first. When no image is configured, Boost falls back to its own bundled
 * "AI generated" stock photo plus a watermark label, both emitted against
 * `body.pagelayout-login #page .login-layout-left` (specificity 1-2-1). Coming later in the
 * cascade is NOT enough on its own - a bare `.login-layout-left` rule here loses on
 * specificity no matter where it appears - so every selector below mirrors Boost's selector
 * exactly. Equal specificity plus later source order is what makes Lovely's unconditional
 * (re)assertion - custom image(s), or gradient - actually render, and what lets the watermark
 * removal take effect.
 *
 * @param theme_config $theme The theme config object.
 * @return string CSS.
 */
function theme_lovely_login_background($theme): string {
    $content = '';

    // Must match theme_boost_get_extra_scss()'s selector - see the docblock above.
    $panel = 'body.pagelayout-login #page .login-layout-left';

    // Shared darkening gradient, layered over each image so the login copy stays legible.
    $shade = 'linear-gradient(180deg, rgba(15, 46, 56, 0.35), rgba(15, 46, 56, 0.55))';

    $images = [];
    foreach (['loginbackgroundimage', 'loginbackgroundimage2', 'loginbackgroundimage3'] as $area) {
        $url = $theme->setting_file_url($area, $area);
        if (!empty($url)) {
            $images[] = $url;
        }
    }

    // Centred login variant: the brand panel is hidden (scss/lovely/variants.scss), so the
    // first image / gradient / video poster becomes a page-level background instead.
    if (($theme->settings->loginposition ?? 'right') === 'centered') {
        $content .= 'body.pagelayout-login #page {';
        if (!empty($images)) {
            $content .= " background-image: {$shade}, url('" . $images[0] . "');";
            $content .= ' background-size: cover; background-position: center;';
        } else {
            $content .= ' background-image: linear-gradient(160deg, #153f4c 0%, #1b5a6b 65%, #227087 100%);';
        }
        $content .= ' }';
    }

    if (empty($images)) {
        // No custom image: (re)apply our own brand-coloured gradient, overriding Boost's
        // bundled stock-photo fallback.
        $content .= $panel . ' {';
        $content .= ' background-image: linear-gradient(160deg, #153f4c 0%, #1b5a6b 65%, #227087 100%);';
        $content .= ' }';
        // Boost's "AI generated image" watermark only makes sense next to Boost's own photo.
        $content .= $panel . '::after { content: none; }';
        return $content;
    }

    // Base image (always visible; the only image when just one is configured).
    $content .= $panel . ' {';
    $content .= " background-image: {$shade}, url('" . $images[0] . "');";
    $content .= ' background-size: cover; background-position: center;';
    $content .= ' }';

    if (count($images) === 1) {
        $content .= $panel . '::after { content: none; }';
        return $content;
    }

    // Slideshow: further images cross-fade on the panel's pseudo-elements. The caption card
    // (.login-layout-left-content) stays readable because it carries z-index: 2 in
    // scss/lovely/login.scss. The ::after image layer replaces Boost's watermark outright.
    $cycle = count($images) * 8; // Seconds for a full rotation, 8s per image.

    $content .= $panel . '::before {';
    $content .= ' content: ""; position: absolute; inset: 0; z-index: 1; opacity: 0;';
    $content .= " background-image: {$shade}, url('" . $images[1] . "');";
    $content .= ' background-size: cover; background-position: center;';
    $content .= " animation: lovely-login-fade-b {$cycle}s infinite;";
    $content .= ' }';

    if (count($images) === 3) {
        $content .= $panel . '::after {';
        $content .= ' content: ""; position: absolute; inset: 0; z-index: 1; opacity: 0;';
        $content .= ' bottom: 0; right: 0; left: 0; top: 0; color: transparent; text-shadow: none;';
        $content .= " background-image: {$shade}, url('" . $images[2] . "');";
        $content .= ' background-size: cover; background-position: center;';
        $content .= " animation: lovely-login-fade-c {$cycle}s infinite;";
        $content .= ' }';
    } else {
        $content .= $panel . '::after { content: none; }';
    }

    // Keyframes: each image gets an equal share of the cycle with short crossfades; the base
    // image shows whenever both overlays are transparent.
    if (count($images) === 3) {
        $content .= '@keyframes lovely-login-fade-b {';
        $content .= ' 0%, 29% { opacity: 0; } 33%, 62% { opacity: 1; } 66%, 100% { opacity: 0; }';
        $content .= ' }';
        $content .= '@keyframes lovely-login-fade-c {';
        $content .= ' 0%, 62% { opacity: 0; } 66%, 95% { opacity: 1; } 100% { opacity: 0; }';
        $content .= ' }';
    } else {
        $content .= '@keyframes lovely-login-fade-b {';
        $content .= ' 0%, 45% { opacity: 0; } 50%, 95% { opacity: 1; } 100% { opacity: 0; }';
        $content .= ' }';
    }

    // Respect reduced-motion preferences: freeze on the base image.
    $content .= '@media (prefers-reduced-motion: reduce) {';
    $content .= " {$panel}::before, {$panel}::after { animation: none; opacity: 0; }";
    $content .= ' }';

    return $content;
}

/**
 * Returns SCSS to append, injected after the main preset content is compiled.
 *
 * @param theme_config $theme The theme config object.
 * @return string
 */
function theme_lovely_get_extra_scss($theme) {
    $content = '';

    // Login page background(s) - see theme_lovely_login_background() for the specificity story.
    $content .= theme_lovely_login_background($theme);

    // @font-face for bundled/custom fonts.
    $content .= theme_lovely_font_faces($theme);

    // Hero slider height + mobile caption behaviour.
    $sliderheight = $theme->settings->sliderheight ?? '24rem';
    if (!preg_match('/^\d+(\.\d+)?(rem|px|em|vh)$/', $sliderheight)) {
        $sliderheight = '24rem'; // Never let a malformed value break the compile.
    }
    $content .= ".lovely-hero .carousel-item, .lovely-hero .lovely-hero-static { min-height: {$sliderheight}; }";
    if (!empty($theme->settings->sliderhidecaptionsmobile)) {
        $content .= '@media (max-width: 767.98px) { .lovely-hero .carousel-caption { display: none; } }';
    }

    // Dashboard banner image behind the page heading.
    $dashboardbannerurl = $theme->setting_file_url('dashboardbanner', 'dashboardbanner');
    if (!empty($dashboardbannerurl)) {
        $content .= 'body.pagelayout-mydashboard #page-header {';
        $content .= " background-image: linear-gradient(rgba(15, 46, 56, 0.55), rgba(15, 46, 56, 0.55)), url('"
            . $dashboardbannerurl . "');";
        $content .= ' background-size: cover; background-position: center;';
        $content .= ' border-radius: 0.875rem; padding: 2.5rem 2rem; margin-top: 1rem;';
        $content .= ' }';
        $content .= 'body.pagelayout-mydashboard #page-header .page-header-headings h1,';
        $content .= 'body.pagelayout-mydashboard #page-header .page-header-headings {';
        $content .= ' color: #fff; text-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);';
        $content .= ' }';
    }

    // Page background (most visible with the boxed layout, but applied whenever configured).
    $pagebgcolor = $theme->settings->pagebackgroundcolor ?? '';
    $pagebgimage = $theme->setting_file_url('pagebackgroundimage', 'pagebackgroundimage');
    $pagebgtint = $theme->settings->pagebackgroundtint ?? '0.35';
    if (!preg_match('/^(0|0?\.\d+)$/', (string) $pagebgtint)) {
        $pagebgtint = '0.35';
    }
    if (!empty($pagebgcolor) || !empty($pagebgimage)) {
        $tintcolor = !empty($pagebgcolor) ? $pagebgcolor : '#0f2e38';
        $content .= 'body {';
        if (!empty($pagebgcolor)) {
            $content .= " background-color: {$pagebgcolor};";
        }
        if (!empty($pagebgimage)) {
            // The tint keeps page-edge contrast predictable over arbitrary images.
            $content .= " background-image: linear-gradient(rgba({$tintcolor}, {$pagebgtint}), "
                . "rgba({$tintcolor}, {$pagebgtint})), url('" . $pagebgimage . "');";
            $content .= ' background-size: cover; background-position: center; background-attachment: fixed;';
        }
        $content .= ' }';
    }

    // Login background video: the brand panel goes transparent so the page-level video wrap
    // (templates/theme_boost/login.mustache) shows through it. Selector matches Boost's
    // specificity - see theme_lovely_login_background().
    $loginvideourl = $theme->setting_file_url('loginbackgroundvideo', 'loginbackgroundvideo');
    if (!empty($loginvideourl)) {
        $content .= 'body.pagelayout-login #page .login-layout-left {';
        $content .= ' background-image: none; background-color: transparent;';
        $content .= ' }';
    }

    // Navbar logo height.
    $logoheight = trim($theme->settings->logoheight ?? '');
    if ($logoheight !== '' && preg_match('/^\d+(\.\d+)?(rem|px|em)$/', $logoheight)) {
        // Same selector Boost uses in scss/moodle/navbar.scss; later source order wins.
        $content .= ".navbar.fixed-top .navbar-brand .logo { max-height: {$logoheight}; }";
    }

    if (!empty($theme->settings->scss)) {
        $content .= $theme->settings->scss;
    }

    return $content;
}

/**
 * Serves files associated with theme_lovely settings (images and fonts).
 *
 * @param stdClass $course
 * @param stdClass $cm
 * @param context $context
 * @param string $filearea
 * @param array $args
 * @param bool $forcedownload
 * @param array $options
 * @return bool
 */
function theme_lovely_pluginfile($course, $cm, $context, $filearea, $args, $forcedownload, array $options = []) {
    $allowed = [
        'loginbackgroundimage', 'loginbackgroundimage2', 'loginbackgroundimage3',
        'loginbackgroundvideo', 'dashboardbanner', 'bodyfontfile', 'headingfontfile',
        'pagebackgroundimage',
    ];
    for ($i = 1; $i <= 16; $i++) {
        $allowed[] = 'slideimage' . $i;
        $allowed[] = 'slidevideo' . $i;
    }
    if ($context->contextlevel == CONTEXT_SYSTEM && in_array($filearea, $allowed, true)) {
        $theme = theme_config::load('lovely');
        if (!array_key_exists('cacheability', $options)) {
            $options['cacheability'] = 'public';
        }
        return $theme->setting_file_serve($filearea, $args, $forcedownload, $options);
    }

    send_file_not_found();
}
