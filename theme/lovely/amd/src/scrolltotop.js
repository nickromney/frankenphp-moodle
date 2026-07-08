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
 * Scroll-to-top button for theme_lovely.
 *
 * NOTE ON THE BUILD: this repository has no Node/grunt toolchain, so amd/build/
 * scrolltotop.min.js is maintained BY HAND as a plain AMD (define) module with identical
 * behaviour - Moodle only ever loads amd/build/<name>.min.js (see core_requirejs::
 * find_one_amd_module()), the ".min" suffix is a naming convention, and nothing requires the
 * file to actually be minified or transpiled. If you edit this file, port the change to
 * amd/build/scrolltotop.min.js too.
 *
 * @module     theme_lovely/scrolltotop
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

const SCROLL_THRESHOLD = 400;

/**
 * Initialise the scroll-to-top button.
 */
export const init = () => {
    const button = document.getElementById('lovely-scrolltotop');
    if (!button) {
        return;
    }

    const onScroll = () => {
        button.hidden = window.scrollY < SCROLL_THRESHOLD;
    };

    window.addEventListener('scroll', onScroll, {passive: true});
    onScroll();

    button.addEventListener('click', () => {
        const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        window.scrollTo({top: 0, behavior: reduced ? 'auto' : 'smooth'});
    });
};
