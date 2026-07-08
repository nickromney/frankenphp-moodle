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
 * Strings for theme_lovely.
 *
 * @package    theme_lovely
 * @copyright  2026 frankenphp-moodle
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

$string['pluginname'] = 'Lovely';
$string['choosereadme'] = 'Lovely is a calm, modern child theme of Boost. It refines Boost\'s palette, type scale, and surfaces (navigation, course cards, forms, and the login screen) into a polished, professional look, and adds a configurable front page (hero slider, marketing spots), themed header and footer, dark mode, locally bundled fonts, and login page enhancements - while keeping full compatibility with Boost-based plugins.';
$string['configtitle'] = 'Lovely';
$string['region-side-pre'] = 'Right';

// Settings tabs.
$string['generalsettings'] = 'General';
$string['sitehomesettings'] = 'Site home';
$string['headersettings'] = 'Header';
$string['footersettings'] = 'Footer';
$string['colourssettings'] = 'Colours';
$string['fontssettings'] = 'Fonts';
$string['loginsettings'] = 'Login';
$string['advancedsettings'] = 'Advanced';

// Preset.
$string['preset'] = 'Theme preset';
$string['preset_desc'] = 'Pick a starting preset for Lovely. The default preset is the hand-tuned Lovely design; "Plain" strips back to unstyled Boost so you can build your own look from scratch.';
$string['presetfiles'] = 'Additional theme preset files';
$string['presetfiles_desc'] = 'Preset files can be used to dramatically alter the appearance of the theme. See <a href="https://docs.moodle.org/en/Boost_Presets">Boost presets</a> for information on creating and sharing your own preset files, and the Lovely and Boost preset files for examples.';

// General - page layout.
$string['pagelayoutheading'] = 'Page layout';
$string['pagelayoutheading_desc'] = 'Overall page chrome: a full-width layout, or a boxed layout with a visible page background around the content.';
$string['pagelayoutstyle'] = 'Page layout style';
$string['pagelayoutstyle_desc'] = '"Wide" (default) fills the window. "Boxed" constrains the page to a centred column and shows the page background around it.';
$string['pagelayoutwide'] = 'Wide (default)';
$string['pagelayoutboxed'] = 'Boxed';
$string['pagebackgroundcolor'] = 'Page background colour';
$string['pagebackgroundcolor_desc'] = 'Colour behind the page content - most visible with the boxed layout. Leave empty for the theme default.';
$string['pagebackgroundimage'] = 'Page background image';
$string['pagebackgroundimage_desc'] = 'Image behind the page content - most visible with the boxed layout.';
$string['pagebackgroundtint'] = 'Page background image tint';
$string['pagebackgroundtint_desc'] = 'How strongly the page background colour is tinted over the background image, keeping the content edges readable.';
$string['tintnone'] = 'None';
$string['tintlight'] = 'Light';
$string['tintmedium'] = 'Medium';
$string['tintstrong'] = 'Strong';

// Site home - hero slider.
$string['heroheading'] = 'Hero slider';
$string['heroheading_desc'] = 'A full-width slideshow at the top of the site home page. Slides with no image are skipped; if no slides have images, a simple brand-coloured hero with the site name is shown instead.';
$string['sliderenabled'] = 'Enable hero slider';
$string['sliderenabled_desc'] = 'Show the hero slider section at the top of the site home page.';
$string['sliderinterval'] = 'Slide interval';
$string['sliderinterval_desc'] = 'Time in milliseconds between automatic slide changes.';
$string['sliderheight'] = 'Slider height';
$string['sliderheight_desc'] = 'The minimum height of the hero slider.';
$string['sliderheightcompact'] = 'Compact';
$string['sliderheightstandard'] = 'Standard';
$string['sliderheighttall'] = 'Tall';
$string['sliderheightgrand'] = 'Grand';
$string['sliderhidecaptionsmobile'] = 'Hide captions on small screens';
$string['sliderhidecaptionsmobile_desc'] = 'Hide slide headings and captions on phones so the imagery stays uncluttered.';
$string['slideimage'] = 'Slide {$a} image';
$string['slideimage_desc'] = 'Background image for this slide. The slide is skipped if no image is set.';
$string['slideheading'] = 'Slide {$a} heading';
$string['slideheading_desc'] = 'Large heading shown on this slide.';
$string['slidecaption'] = 'Slide {$a} caption';
$string['slidecaption_desc'] = 'Supporting text shown under the heading on this slide.';
$string['slidectalabel'] = 'Slide {$a} button label';
$string['slidectalabel_desc'] = 'Label for the call-to-action button on this slide. Leave empty for no button.';
$string['slidectaurl'] = 'Slide {$a} button URL';
$string['slidectaurl_desc'] = 'Destination for the call-to-action button on this slide.';
$string['slidevideo'] = 'Slide {$a} video';
$string['slidevideo_desc'] = 'Optional MP4/WebM video for this slide, shown muted and looping over the slide image (the image doubles as the poster and as the static fallback for visitors who prefer reduced motion). Keep files short and small.';
$string['slidertransition'] = 'Slide transition';
$string['slidertransition_desc'] = 'How slides change: a horizontal slide, a cross-fade, or a cross-fade with a slow, subtle zoom on the image. All motion is disabled for visitors who prefer reduced motion.';
$string['transitionslide'] = 'Slide (default)';
$string['transitionfade'] = 'Fade';
$string['transitionzoom'] = 'Fade with slow zoom';
$string['heroplaypause'] = 'Pause or resume the slideshow';

// Site home - marketing spots.
$string['marketingheading'] = 'Marketing spots';
$string['marketingheading_desc'] = 'A row of up to four highlight cards under the hero slider. Spots with no heading are skipped.';
$string['marketingenabled'] = 'Enable marketing spots';
$string['marketingenabled_desc'] = 'Show the marketing spots section on the site home page.';
$string['marketingicon'] = 'Spot {$a} icon';
$string['marketingicon_desc'] = 'A Font Awesome icon name, for example "fa-graduation-cap" or "graduation-cap". The bundled icon set is Font Awesome 6 Free (solid).';
$string['marketingheadingsetting'] = 'Spot {$a} heading';
$string['marketingheadingsetting_desc'] = 'Heading for this marketing spot. The spot is skipped if empty.';
$string['marketingtext'] = 'Spot {$a} text';
$string['marketingtext_desc'] = 'Short supporting text for this marketing spot.';
$string['marketingurl'] = 'Spot {$a} link URL';
$string['marketingurl_desc'] = 'Optional link for this marketing spot; the whole card becomes clickable.';

// Site home - course/category presentation.
$string['frontpagelistingsheading'] = 'Course and category listings';
$string['frontpagelistingsheading_desc'] = 'Presentation options for the standard Moodle front page sections (available courses, course categories, and site announcements).';
$string['frontpagecoursecards'] = 'Show available courses as cards';
$string['frontpagecoursecards_desc'] = 'Restyle the "Available courses" front page section into a responsive card grid with course images.';
$string['frontpagecategorycards'] = 'Show course categories as cards';
$string['frontpagecategorycards_desc'] = 'Restyle the course categories front page section into a responsive card grid.';
$string['frontpagenewsblog'] = 'Blog-style site announcements';
$string['frontpagenewsblog_desc'] = 'Restyle the site announcements front page section into blog-style cards.';

// Site home - dashboard.
$string['dashboardheading'] = 'Dashboard';
$string['dashboardheading_desc'] = 'Options for the user dashboard.';
$string['dashboardbanner'] = 'Dashboard banner image';
$string['dashboardbanner_desc'] = 'Optional image shown behind the dashboard page heading.';

// Header.
$string['headerlayout'] = 'Header layout';
$string['headerlayout_desc'] = 'Arrangement of the navigation bar: the default Boost arrangement, a centred logo, or a compact minimal bar.';
$string['headerlayoutdefault'] = 'Default';
$string['headerlayoutcentered'] = 'Centred logo';
$string['headerlayoutcompact'] = 'Compact';
$string['topbarheading'] = 'Top bar';
$string['topbarheading_desc'] = 'A slim contact/social strip above the main navigation bar.';
$string['topbarenabled'] = 'Enable top bar';
$string['topbarenabled_desc'] = 'Show the top bar above the main navigation.';
$string['topbarphone'] = 'Phone number';
$string['topbarphone_desc'] = 'Contact phone number shown in the top bar. Leave empty to hide.';
$string['topbaremail'] = 'Email address';
$string['topbaremail_desc'] = 'Contact email address shown in the top bar. Leave empty to hide.';
$string['topbarshowlogin'] = 'Show login link in top bar';
$string['topbarshowlogin_desc'] = 'Show a login link on the right of the top bar for guests.';
$string['topbarshowsocial'] = 'Show social icons in top bar';
$string['topbarshowsocial_desc'] = 'Show the social network icons (configured on the Footer tab) in the top bar as well.';
$string['navbarheading'] = 'Navigation bar';
$string['navbarheading_desc'] = 'Options for the main navigation bar.';
$string['stickyheader'] = 'Sticky navigation bar';
$string['stickyheader_desc'] = 'Keep the navigation bar fixed to the top of the window while scrolling. Turn off to let it scroll away with the page.';
$string['logoheight'] = 'Logo height';
$string['logoheight_desc'] = 'Maximum height of the logo in the navigation bar, for example "36px" or "2.5rem". Leave empty for the theme default. The logo itself is uploaded under Site administration > Appearance > Logos.';

// Footer.
$string['footercolumnsheading'] = 'Footer columns';
$string['footercolumnsheading_desc'] = 'Up to four columns of rich content shown in the site footer. Empty columns are skipped; if all four are empty the columns area is hidden.';
$string['footercolumn'] = 'Footer column {$a}';
$string['footercolumn_desc'] = 'Content for footer column {$a}. Start with a heading tag (for example &lt;h4&gt;) to give the column a styled title.';
$string['socialheading'] = 'Social networks';
$string['socialheading_desc'] = 'Links to your social network profiles, shown as icons in the footer (and optionally the top bar). Leave a field empty to hide that icon.';
$string['socialfacebook'] = 'Facebook URL';
$string['socialx'] = 'X (Twitter) URL';
$string['socialinstagram'] = 'Instagram URL';
$string['sociallinkedin'] = 'LinkedIn URL';
$string['socialyoutube'] = 'YouTube URL';
$string['socialgithub'] = 'GitHub URL';
$string['socialmastodon'] = 'Mastodon URL';
$string['socialwebsite'] = 'Website URL';
$string['socialurl_desc'] = 'Full URL of your profile on this network.';
$string['footnoteheading'] = 'Footnote';
$string['footnoteheading_desc'] = 'The bottom strip of the footer.';
$string['footnote'] = 'Footnote';
$string['footnote_desc'] = 'Copyright or closing text shown at the very bottom of every page.';
$string['scrolltotopenabled'] = 'Scroll-to-top button';
$string['scrolltotopenabled_desc'] = 'Show a small button in the bottom corner that scrolls back to the top of the page. The scroll is instant for users who prefer reduced motion.';
$string['scrolltotop'] = 'Scroll to top';

// Colours.
$string['brandcolor'] = 'Primary colour';
$string['brandcolor_desc'] = 'The main brand colour used for links, buttons, and highlights throughout the site.';
$string['secondarycolor'] = 'Secondary / accent colour';
$string['secondarycolor_desc'] = 'A warm accent colour used sparingly for highlights, badges, and secondary calls to action.';
$string['headerbgcolor'] = 'Header background colour';
$string['headerbgcolor_desc'] = 'Background colour of the navigation bar. Leave empty for the theme default (a deep shade of the primary colour). Pick a dark colour - the navigation text is white.';
$string['footerbgcolor'] = 'Footer background colour';
$string['footerbgcolor_desc'] = 'Background colour of the themed footer. Leave empty for the theme default. Pick a dark colour - the footer text is light.';
$string['linkcolor'] = 'Link colour';
$string['linkcolor_desc'] = 'Colour of text links. Leave empty to use the primary colour. Must keep at least 4.5:1 contrast against white to meet WCAG AA.';
$string['buttonradius'] = 'Button corner radius';
$string['buttonradius_desc'] = 'How rounded buttons and inputs are.';
$string['buttonradiussquare'] = 'Square';
$string['buttonradiussubtle'] = 'Subtle';
$string['buttonradiussoft'] = 'Soft (default)';
$string['buttonradiusround'] = 'Round';
$string['buttonradiuspill'] = 'Pill';
$string['basefontsize'] = 'Base font size';
$string['basefontsize_desc'] = 'The root text size everything else scales from.';
$string['drawerbgcolor'] = 'Drawer background colour';
$string['drawerbgcolor_desc'] = 'Background colour of the course index and block drawers. Leave empty for the theme default. Pick a light colour in light mode (drawer text follows the body text colour), or leave empty to let dark mode handle it.';
$string['darkmode'] = 'Dark mode';
$string['darkmode_desc'] = 'Compile the theme with a dark colour scheme (site-wide). All dark palette combinations meet WCAG AA contrast.';

// Fonts.
$string['fontsheading'] = 'Font choices';
$string['fontsheading_desc'] = 'Lovely never loads fonts from external services. The bundled choices (Inter, Source Sans 3, Lora) are packaged inside the theme as variable WOFF2 files under their SIL Open Font License; "System" uses the fonts already installed on each visitor\'s device; "Custom upload" serves a font file you upload here.';
$string['bodyfont'] = 'Body font';
$string['bodyfont_desc'] = 'Font used for body text.';
$string['headingfont'] = 'Heading font';
$string['headingfont_desc'] = 'Font used for headings. "Same as body" inherits the body font.';
$string['fontsystem'] = 'System font stack (default)';
$string['fontinter'] = 'Inter (bundled)';
$string['fontsourcesans'] = 'Source Sans 3 (bundled)';
$string['fontlora'] = 'Lora (bundled, serif)';
$string['fontcustom'] = 'Custom upload';
$string['fontsameasbody'] = 'Same as body';
$string['bodyfontfile'] = 'Custom body font file';
$string['bodyfontfile_desc'] = 'A WOFF2, WOFF, or TTF font file used when the body font is set to "Custom upload".';
$string['headingfontfile'] = 'Custom heading font file';
$string['headingfontfile_desc'] = 'A WOFF2, WOFF, or TTF font file used when the heading font is set to "Custom upload".';

// Login.
$string['loginbackgroundimage'] = 'Login page background image';
$string['loginbackgroundimage_desc'] = 'An image shown behind the login card on the login page. If no image is set, a soft brand-coloured backdrop is used instead.';
$string['loginbackgroundimage2'] = 'Login background image 2';
$string['loginbackgroundimage2_desc'] = 'Optional second login background image. When two or more images are set they cross-fade in a slow slideshow (disabled for users who prefer reduced motion).';
$string['loginbackgroundimage3'] = 'Login background image 3';
$string['loginbackgroundimage3_desc'] = 'Optional third login background image for the login slideshow.';
$string['loginposition'] = 'Login form position';
$string['loginposition_desc'] = 'Where the login form sits: on the right of the brand panel (default), on the left, or as a centred card over the full background.';
$string['loginpositionright'] = 'Right (default)';
$string['loginpositionleft'] = 'Left';
$string['loginpositioncentered'] = 'Centred';
$string['loginbackgroundvideo'] = 'Login background video';
$string['loginbackgroundvideo_desc'] = 'Optional MP4/WebM video played muted and looping behind the login page. The login background image is used as the poster and as the static fallback for visitors who prefer reduced motion. To hide the username/password form on SSO-only sites, use the core setting "Show login form" under Site administration > Plugins > Authentication.';
$string['loginmodalenabled'] = 'Modal login';
$string['loginmodalenabled_desc'] = 'Open a login dialog from the "Log in" link in the navigation bar instead of navigating to the login page. The full login page remains available at its usual URL.';
$string['loginmodaltitle'] = 'Log in to {$a}';
$string['backtosite'] = 'Back to site';

// Courses.
$string['coursesheading'] = 'Courses';
$string['coursesheading_desc'] = 'Course page presentation options.';
$string['courseheaderbanner'] = 'Course image header banner';
$string['courseheaderbanner_desc'] = 'Show the course image as a banner behind the course page header, with a legibility overlay. Courses without an image keep the standard header.';
$string['activityiconstyle'] = 'Activity icon style';
$string['activityiconstyle_desc'] = 'How activity icons are drawn: rounded tiles (default), circles, or a minimal monochrome style.';
$string['iconstiles'] = 'Rounded tiles (default)';
$string['iconscircles'] = 'Circles';
$string['iconsmono'] = 'Minimal monochrome';

// Raw SCSS.
$string['rawscss'] = 'Raw SCSS';
$string['rawscss_desc'] = 'Use this field to provide SCSS code which will be injected at the end of the style sheet.';
$string['rawscsspre'] = 'Raw initial SCSS';
$string['rawscsspre_desc'] = 'In this field you can provide initialising SCSS code, it will be injected before everything else. Most of the time you will use this setting to define variables.';

// Privacy.
$string['privacy:metadata'] = 'The Lovely theme does not store any personal data about any user.';
