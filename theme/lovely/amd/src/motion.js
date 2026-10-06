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
 * Ambient-motion controller for theme_lovely (hero slide videos, login background video,
 * and the hero pause/play control).
 *
 * Videos marked data-lovely-autoplay carry NO autoplay attribute in markup; this module
 * plays them only when the visitor does not prefer reduced motion (their poster image is the
 * static fallback). The hero pause button satisfies WCAG 2.2.2 by stopping both the
 * Bootstrap carousel autoplay and every slide video with one control.
 *
 * NOTE ON THE BUILD: this repository has no Node/grunt toolchain, so amd/build/motion.min.js
 * is maintained BY HAND as a plain AMD (define) module with identical behaviour - Moodle
 * only ever loads amd/build/<name>.min.js and nothing requires the file to actually be
 * minified. If you edit this file, port the change to amd/build/motion.min.js too.
 *
 * @module     theme_lovely/motion
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

/**
 * Load Bootstrap's Carousel class from the module this Moodle branch provides.
 *
 * Moodle 5.2 ships theme_boost/bootstrap/carousel (default export); 5.3 ships a core
 * "bootstrap" bundle (named export). The layout passes the right name, so the module is only
 * requested when the hero pause control is used and never 404s on either branch.
 *
 * @param {String} moduleName AMD module name.
 * @returns {Promise<Function>} The Carousel class.
 */
const loadCarousel = (moduleName) => new Promise((resolve, reject) => {
    window.require([moduleName], (module) => resolve(module.Carousel || module.default || module), reject);
});

const reducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/**
 * Play every opted-in ambient video unless the visitor prefers reduced motion.
 */
const autoplayVideos = () => {
    if (reducedMotion()) {
        return;
    }
    document.querySelectorAll('video[data-lovely-autoplay]').forEach((video) => {
        const promise = video.play();
        if (promise) {
            promise.catch(() => null); // Autoplay rejection (e.g. power saving) is fine.
        }
    });
};

/**
 * Wire the hero pause/play button: one control stops carousel autoplay and slide videos.
 */
const initHeroPause = (carouselModule) => {
    const button = document.querySelector('.lovely-hero-pause');
    const carouselEl = document.getElementById('lovely-hero-carousel');
    if (!button || !carouselEl || !carouselModule) {
        return;
    }

    button.addEventListener('click', async() => {
        const playing = button.dataset.lovelyState === 'playing';
        const Carousel = await loadCarousel(carouselModule);
        const carousel = Carousel.getOrCreateInstance(carouselEl);

        if (playing) {
            carousel.pause();
            carouselEl.querySelectorAll('video[data-lovely-autoplay]').forEach((video) => video.pause());
            button.dataset.lovelyState = 'paused';
            button.setAttribute('aria-pressed', 'true');
        } else {
            carousel.cycle();
            if (!reducedMotion()) {
                carouselEl.querySelectorAll('video[data-lovely-autoplay]').forEach((video) => {
                    const promise = video.play();
                    if (promise) {
                        promise.catch(() => null);
                    }
                });
            }
            button.dataset.lovelyState = 'playing';
            button.setAttribute('aria-pressed', 'false');
        }
    });
};

/**
 * Initialise ambient motion handling.
 *
 * @param {String} [carouselModule] AMD module providing Bootstrap's Carousel; omit when the page
 *     has no hero carousel (the login background video needs none).
 */
export const init = (carouselModule) => {
    autoplayVideos();
    initHeroPause(carouselModule);
};
