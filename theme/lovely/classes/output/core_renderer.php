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

namespace theme_lovely\output;

use moodle_url;

/**
 * Core renderer for theme_lovely.
 *
 * Extends Boost's renderer with zero-argument helper methods that the theme's Mustache
 * templates call via {{{ output.method_name }}} (Moodle's Mustache engine resolves missing
 * context keys against the renderer). Nothing here overrides core rendering behaviour except
 * body_attributes(), which only appends theme body classes.
 *
 * @package    theme_lovely
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class core_renderer extends \theme_boost\output\core_renderer {

    /**
     * Add Lovely's feature body classes on every page.
     *
     * @param string|array $additionalclasses Any additional classes for the body tag.
     * @return string HTML attributes for the body tag.
     */
    public function body_attributes($additionalclasses = []) {
        if (!is_array($additionalclasses)) {
            $additionalclasses = explode(' ', $additionalclasses);
        }

        $settings = $this->page->theme->settings;
        if (empty($settings->stickyheader) && isset($settings->stickyheader)) {
            $additionalclasses[] = 'lovely-navbar-unstuck';
        }
        if (!empty($settings->topbarenabled)) {
            $additionalclasses[] = 'lovely-has-topbar';
        }
        if (!empty($settings->darkmode)) {
            $additionalclasses[] = 'lovely-dark';
        }
        if (($settings->pagelayoutstyle ?? 'wide') === 'boxed') {
            $additionalclasses[] = 'lovely-boxed';
        }
        $headerlayout = $settings->headerlayout ?? 'default';
        if ($headerlayout === 'centered' || $headerlayout === 'compact') {
            $additionalclasses[] = 'lovely-header-' . $headerlayout;
        }
        $iconstyle = $settings->activityiconstyle ?? 'tiles';
        if ($iconstyle === 'circles' || $iconstyle === 'mono') {
            $additionalclasses[] = 'lovely-icons-' . $iconstyle;
        }
        if ($this->page->pagelayout === 'login') {
            $loginposition = $settings->loginposition ?? 'right';
            if ($loginposition === 'left' || $loginposition === 'centered') {
                $additionalclasses[] = 'lovely-login-' . $loginposition;
            }
        }

        return parent::body_attributes($additionalclasses);
    }

    /**
     * Wrap the page header in a course-image banner on course pages when enabled.
     *
     * Uses the same course image the card listings use (core's course_image cache via
     * course_summary_exporter). Courses without an image, non-course pages, and the site
     * home all fall straight through to Boost's standard header.
     *
     * @return string HTML.
     */
    public function full_header() {
        $html = parent::full_header();

        if (empty($this->page->theme->settings->courseheaderbanner)) {
            return $html;
        }
        $course = $this->page->course;
        if (empty($course->id) || $course->id == SITEID) {
            return $html;
        }
        if (!in_array($this->page->pagelayout, ['course', 'incourse'], true)) {
            return $html;
        }
        $imageurl = \core_course\external\course_summary_exporter::get_course_image($course);
        if (empty($imageurl)) {
            return $html;
        }

        return \html_writer::div($html, 'lovely-course-banner', [
            'style' => "background-image: url('" . $imageurl . "');",
        ]);
    }

    /**
     * The login page background video markup, or '' when none is configured.
     *
     * Rendered by the theme_boost/login template override. The video carries no autoplay
     * attribute: theme_lovely/motion plays it only when the visitor does not prefer reduced
     * motion (the poster - the login background image, if any - is the static fallback).
     *
     * @return string HTML.
     */
    public function lovely_login_video(): string {
        $theme = $this->page->theme;
        $videourl = $theme->setting_file_url('loginbackgroundvideo', 'loginbackgroundvideo');
        if (empty($videourl)) {
            return '';
        }

        $posterurl = $theme->setting_file_url('loginbackgroundimage', 'loginbackgroundimage');

        return $this->render_from_template('theme_lovely/login_video', [
            'videourl' => $videourl,
            'posterurl' => $posterurl ?: null,
        ]);
    }

    /**
     * The top bar above the main navigation (phone / email / social / login), or '' when disabled.
     *
     * Rendered from the navbar template override via {{{ output.lovely_topbar }}}.
     *
     * @return string HTML.
     */
    public function lovely_topbar(): string {
        $settings = $this->page->theme->settings;
        if (empty($settings->topbarenabled)) {
            return '';
        }

        $phone = trim($settings->topbarphone ?? '');
        $email = trim($settings->topbaremail ?? '');

        $context = [
            'phone' => $phone !== '' ? $phone : null,
            'phonehref' => $phone !== '' ? 'tel:' . preg_replace('/[^+0-9]/', '', $phone) : null,
            'email' => $email !== '' ? $email : null,
            'showlogin' => !empty($settings->topbarshowlogin) && !isloggedin(),
            'loginurl' => (new moodle_url('/login/index.php'))->out(false),
            'socialicons' => !empty($settings->topbarshowsocial) ? $this->lovely_social_icons() : [],
        ];

        return $this->render_from_template('theme_lovely/topbar', $context);
    }

    /**
     * The themed footer content (columns, social icons, footnote), or '' when nothing is configured.
     *
     * Rendered from the footer template override via {{{ output.lovely_footer }}}.
     *
     * @return string HTML.
     */
    public function lovely_footer(): string {
        $settings = $this->page->theme->settings;

        $columns = [];
        for ($i = 1; $i <= 4; $i++) {
            $raw = $settings->{'footercolumn' . $i} ?? '';
            if (trim(html_to_text($raw ?? '')) === '') {
                continue;
            }
            // Default cleaning keeps rich HTML (links, lists, images) but strips scripts -
            // this output reaches every visitor including guests, so no noclean here.
            $columns[] = ['content' => format_text($raw, FORMAT_HTML)];
        }

        $social = $this->lovely_social_icons();

        $footnote = $settings->footnote ?? '';
        $hasfootnote = trim(html_to_text($footnote ?? '')) !== '';

        if (empty($columns) && empty($social) && !$hasfootnote) {
            return '';
        }

        $context = [
            'columns' => $columns,
            'hascolumns' => !empty($columns),
            'columnclass' => 'col-md-' . (12 / max(1, min(4, count($columns)))),
            'socialicons' => $social,
            'hassocial' => !empty($social),
            'footnote' => $hasfootnote ? format_text($footnote, FORMAT_HTML) : null,
        ];

        return $this->render_from_template('theme_lovely/footer_content', $context);
    }

    /**
     * The configured social network links as icon metadata for templates.
     *
     * @return array[] Each entry: name, url, icon (Font Awesome class), label.
     */
    public function lovely_social_icons(): array {
        $settings = $this->page->theme->settings;

        // Network => Font Awesome 6 Free class (fa-brands where available).
        $networks = [
            'facebook' => 'fa-brands fa-facebook-f',
            'x' => 'fa-brands fa-x-twitter',
            'instagram' => 'fa-brands fa-instagram',
            'linkedin' => 'fa-brands fa-linkedin-in',
            'youtube' => 'fa-brands fa-youtube',
            'github' => 'fa-brands fa-github',
            'mastodon' => 'fa-brands fa-mastodon',
            'website' => 'fa-solid fa-globe',
        ];

        $icons = [];
        foreach ($networks as $network => $iconclass) {
            $url = trim($settings->{'social' . $network} ?? '');
            if ($url === '') {
                continue;
            }
            $icons[] = [
                'name' => $network,
                'url' => $url,
                'icon' => $iconclass,
                'label' => get_string('social' . $network, 'theme_lovely'),
            ];
        }

        return $icons;
    }

    /**
     * Whether the modal login is active for the current request (enabled + not logged in).
     *
     * Used by the core/user_menu template override to turn the plain "Log in" link into a
     * modal trigger.
     *
     * @return bool
     */
    public function lovely_loginmodal_enabled(): bool {
        $settings = $this->page->theme->settings;
        return !empty($settings->loginmodalenabled) && !isloggedin();
    }

    /**
     * The login modal markup (a real POST to /login/index.php with a valid logintoken), or ''.
     *
     * Rendered once per page from the footer template override.
     *
     * @return string HTML.
     */
    public function lovely_login_modal(): string {
        global $SITE;

        if (!$this->lovely_loginmodal_enabled()) {
            return '';
        }

        $context = [
            'loginurl' => (new moodle_url('/login/index.php'))->out(false),
            'logintoken' => \core\session\manager::get_login_token(),
            'sitename' => format_string($SITE->fullname, true,
                ['context' => \context_course::instance(SITEID), 'escape' => false]),
            'forgoturl' => (new moodle_url('/login/forgot_password.php'))->out(false),
            'canloginasguest' => $this->page->pagelayout !== 'login' && !empty(get_config('core', 'guestloginbutton')),
        ];

        return $this->render_from_template('theme_lovely/login_modal', $context);
    }

    /**
     * Whether the scroll-to-top button should render.
     *
     * @return bool
     */
    public function lovely_scrolltotop_enabled(): bool {
        return !empty($this->page->theme->settings->scrolltotopenabled);
    }
}
