# =========================================================================================
#  1. Core Setup & Theme Initialization
# =========================================================================================

import catppuccin

## Load settings configured via GUI (False to ignore GUI changes and force config.py settings)
config.load_autoconfig(False)

catppuccin.setup(c, "mocha", True)

# =========================================================================================
#  2. Base Behavior & Session Options
# =========================================================================================

config.set("auto_save.interval", 15000)  # ms
config.set("auto_save.session", True)
config.set("backend", "webengine")  # webengine/webkit
config.set("colors.webpage.preferred_color_scheme", "dark")
config.set("session.default_name", "autosave")
config.set("session.lazy_restore", True)
config.set("confirm_quit", ["downloads"])

# =========================================================================================
#  3. Completion Window Settings
# =========================================================================================

config.set("completion.cmd_history_max_items", 100)
config.set("completion.delay", 0)  # ms
config.set("completion.height", "50%")
config.set("completion.min_chars", 1)
config.set("completion.open_categories", ["searchengines", "quickmarks", "bookmarks", "history"])
config.set("completion.quick", True)
config.set("completion.show", "always")  # always/never/searching
config.set("completion.use_best_match", False)
config.set("completion.web_history.max_items", -1)  # -1 = unlimited

# =========================================================================================
#  4. Content & Security Configurations
# =========================================================================================

config.set("content.autoplay", True)
config.set("content.blocking.enabled", True)
config.set("content.blocking.method", "both")  # both/hosts/adblock
config.set("content.cookies.accept", "no-3rdparty")  # all/no-3rdparty/never/no-unknown-3rdparty
config.set("content.cookies.store", True)
config.set("content.default_encoding", "utf-8")
config.set("content.desktop_capture", "ask")
config.set("content.dns_prefetch", True)
config.set("content.fullscreen.window", False)
config.set("content.geolocation", "ask")
config.set("content.headers.accept_language", "en-US,en;q=0.9")
config.set("content.headers.do_not_track", True)
config.set("content.headers.referer", "same-domain")
config.set("content.javascript.alert", True)
config.set("content.javascript.can_close_tabs", False)
config.set("content.javascript.can_open_tabs_automatically", False)
config.set("content.javascript.enabled", True)
config.set("content.javascript.prompt", True)
config.set("content.local_content_can_access_file_urls", True)
config.set("content.local_content_can_access_remote_urls", False)
config.set("content.local_storage", True)
config.set("content.media.video_capture", "ask")
config.set("content.mouse_lock", "ask")
config.set("content.notifications.enabled", True)
config.set("content.pdfjs", False)
config.set("content.persistent_storage", "ask")
config.set("content.print_element_backgrounds", True)
config.set("content.private_browsing", False)
config.set("content.proxy", "none")
config.set("content.proxy_dns_requests", True)
config.set("content.register_protocol_handler", "ask")
config.set("content.site_specific_quirks.enabled", True)
config.set("content.webgl", True)
config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.xss_auditing", True)

# =========================================================================================
#  5. Downloads Setup
# =========================================================================================

config.set("downloads.location.prompt", True)
config.set("downloads.location.remember", True)
config.set("downloads.location.suggestion", "path")
config.set("downloads.open_dispatcher", None)
config.set("downloads.position", "bottom")  # top/bottom
config.set("downloads.remove_finished", 3000)  # ms

# =========================================================================================
#  6. Fonts, Styling, & UI Colors
# =========================================================================================

config.set("fonts.default_family", ["Iosevka Nerd Font", "Courier", "Liberation Mono", "monospace", "Fixed", "Consolas", "Terminal"])
config.set("fonts.default_size", "16pt")
config.set("statusbar.position", "bottom")  # top/bottom
config.set("statusbar.widgets", ["keypress", "url", "scroll", "history", "tabs", "progress"])
config.set("window.hide_decoration", True)  # titlebar/borders
config.set("window.title_format", "{perc}{current_title}{title_sep}qutebrowser")

# =========================================================================================
#  7. Hints Setup
# =========================================================================================

config.set("hints.auto_follow", "always")
config.set("hints.find_implementation", "python")  # javascript/python
config.set("hints.hide_unmatched_rapid_hints", True)
config.set("hints.leave_on_load", True)
config.set("hints.min_chars", 1)
config.set("hints.mode", "letter")  # letter/number
config.set("hints.scatter", True)
config.set("hints.uppercase", False)

# =========================================================================================
#  8. Input, Navigation, & Search Options
# =========================================================================================

## External editor command (used to edit text fields in Neovim)
config.set("editor.command", ["kitty", "-e", "nvim", "{file}"])
config.set("editor.encoding", "utf-8")
config.set("history_gap_interval", 30)  # seconds
config.set("input.escape_quits_reporter", True)
config.set("input.forward_unbound_keys", "auto")
config.set("input.insert_mode.auto_enter", True)
config.set("input.insert_mode.auto_leave", True)
config.set("input.insert_mode.auto_load", True)
config.set("input.insert_mode.leave_on_load", True)
config.set("new_instance_open_target", "tab")
config.set("new_instance_open_target_window", "last-focused")
config.set("prompt.filebrowser", True)
config.set("prompt.radius", 8)
config.set("qt.chromium.low_end_device_mode", "never")
config.set("qt.chromium.process_model", "process-per-site-instance")
config.set("qt.workarounds.remove_service_workers", True)
config.set("scrolling.bar", "when-searching")
config.set("scrolling.smooth", False)
config.set("search.ignore_case", "smart")  # smart/case-sensitive/ignore-case
config.set("search.incremental", True)
config.set("spellcheck.languages", ["en-US", "de-DE"])

# =========================================================================================
#  9. Tabs Settings
# =========================================================================================

config.set("tabs.background", True)
config.set("tabs.favicons.scale", 1.000000)
config.set("tabs.favicons.show", "always")  # always/never/switching
config.set("tabs.indicator.width", 3)
config.set("tabs.last_close", "ignore")
config.set("tabs.max_width", -1)
config.set("tabs.min_width", -1)
config.set("tabs.new_position.related", "next")
config.set("tabs.position", "top")  # top/bottom/left/right
config.set("tabs.select_on_remove", "next")
config.set("tabs.show", "always")  # always/never/switching
config.set("tabs.tabs_are_windows", False)
config.set("tabs.title.alignment", "left")
config.set("tabs.title.format", "{audio}{index}: {private}{current_title}")
config.set("tabs.tooltips", True)
config.set("tabs.undo_stack_size", 100)
config.set("tabs.wrap", True)

# =========================================================================================
#  10. URLs & Zoom Settings
# =========================================================================================

config.set("url.auto_search", "naive")
config.set("url.default_page", "https://startpage.com")
config.set("url.open_base_url", True)
config.set("url.start_pages", ["https://startpage.com"])
config.set("zoom.default", "110%")
config.set("zoom.levels", ["25%", "33%", "50%", "67%", "75%", "90%", "100%", "110%", "125%", "150%", "175%", "200%", "250%", "300%", "400%", "500%"])
config.set("zoom.mouse_divider", 512)

# =========================================================================================
#  11. Key Bindings (Insert & Normal Modes)
# =========================================================================================

config.bind("<Ctrl-+>", "zoom-in", mode="insert")
config.bind("<Ctrl-->", "zoom-out", mode="insert")
config.bind("<Ctrl-0>", "zoom", mode="insert")
config.bind("<Ctrl-Shift-p>", "spawn --userscript qute-lastpass --password-only", mode="insert")
config.bind("<Ctrl-Shift-u>", "spawn --userscript qute-lastpass --username-only", mode="insert")
config.bind("<Ctrl-e>", "edit-text", mode="insert")
config.bind("<Ctrl-i>", "edit-text", mode="insert")
config.bind("<Ctrl-p>", "hint --first inputs ;; spawn --userscript qute-lastpass", mode="insert")
config.bind("<Ctrl-s>", "jseval document.querySelectorAll(\"input[type=password]\").forEach(i => { i.type = \"text\" })", mode="insert")
config.bind("<Ctrl-u>", "spawn --userscript qute-lastpass --username-only", mode="insert")
config.bind("<Escape>", "mode-leave ;; jseval -q document.activeElement.blur()", mode="insert")
config.bind("+", "zoom-in", mode="normal")
config.bind(",<Space>", "search", mode="normal")
config.bind(",C", "tab-only", mode="normal")
config.bind(",M", "hint links spawn --detach mpv {hint-url}", mode="normal")
config.bind(",ad", "spawn --detach yt-dlp -x --audio-format mp3 {url}", mode="normal")
config.bind(",b", "set-cmd-text -s :buffer", mode="normal")
config.bind(",c", "tab-close", mode="normal")
config.bind(",e", "set-cmd-text -s :open", mode="normal")
config.bind(",h", "history", mode="normal")
config.bind(",m", "spawn --detach mpv {url}", mode="normal")
config.bind(",q", "tab-prev", mode="normal")
config.bind(",vd", "spawn --detach yt-dlp -f best {url}", mode="normal")
config.bind(",w", "tab-next", mode="normal")
config.bind("-", "zoom-out", mode="normal")
config.bind("<Alt-D>", "edit-url", mode="normal")
config.bind("<Ctrl-+>", "zoom-in", mode="normal")
config.bind("<Ctrl-->", "zoom-out", mode="normal")
config.bind("<Ctrl-0>", "zoom", mode="normal")
config.bind("<Ctrl-Shift-Tab>", "tab-prev", mode="normal")
config.bind("<Ctrl-Tab>", "tab-next", mode="normal")
config.bind("<Ctrl-a>", "mode-enter passthrough", mode="normal")
config.bind("<Ctrl-f>", "set-cmd-text /", mode="normal")
config.bind("<Ctrl-i>", "forward", mode="normal")
config.bind("<Ctrl-o>", "back", mode="normal")
config.bind("<Ctrl-p>", "lastpass", mode="normal")
config.bind("=", "zoom", mode="normal")
config.bind("?", "set-cmd-text :open -t ?", mode="normal")
config.bind("AA", "quickmark-add {url} '{title}'", mode="normal")
config.bind("F", "hint links tab-bg", mode="normal")
config.bind("J", "tab-prev", mode="normal")
config.bind("K", "tab-next", mode="normal")
config.bind("aa", "quickmark-add {url} {title}", mode="normal")
config.bind("gi", "hint inputs", mode="normal")
config.bind("xb", "config-cycle statusbar.show always never", mode="normal")
config.bind("xt", "config-cycle tabs.show always never", mode="normal")
config.bind("xx", "config-cycle statusbar.show always never;; config-cycle tabs.show always never", mode="normal")

# =========================================================================================
#  12. Command Aliases
# =========================================================================================

c.aliases = {
    "adblock-toggle": "config-cycle -t content.blocking.enabled",
    "brave": "spawn --detach brave {url}",
    "librewolf": "spawn --detach librewolf {url}",
    "incognito": "open --private",
    "keepassxc": "hint --first inputs ;; spawn --userscript qute-keepassxc",
    "mpv": "spawn --detach mpv {url}",
    "o": "open",
    "q": "quit",
    "qrcode": "spawn kitty -1 qrcode-terminal '{url}'",
    "wq": "quit --save",
    "x": "quit --save",
}

# =========================================================================================
#  13. Search Engines and URLs
# =========================================================================================

c.url.searchengines = {
    "!az": "https://www.amazon.de/s?k={}",
    "!aur": "https://aur.archlinux.org/packages/?SB=p&SO=d&O=0&K={}",
    "!aw": "https://wiki.archlinux.org/index.php?search={}",
    "!ddg": "https://duckduckgo.com/?q={}",
    "!ebay": "https://www.ebay.de/sch/i.html?_nkw={}",
    "!fs": "https://fakespot.com/analyze?url={}",
    "!g": "https://google.de/search?q={}",
    "!gh": "https://github.com/search?type=Repositories&q={}",
    "!gi": "https://www.google.com/search?tbm=isch&q={}",
    "!gm": "https://www.google.de/maps/search/{}",
    "!id": "https://www.idealo.de/preisvergleich/MainSearchProductCategory.html?q={}",
    "!nix": "https://search.nixos.org/packages?query={}",
    "!r": "https://www.reddit.com/r/{}/",
    "!s": "https://startpage.com/search?q={}",
    "!so": "https://stackoverflow.com/search?q={}",
    "!sx": "https://searx.be/?q={}",
    "!yt": "https://www.youtube.com/results?search_query={}",
    "!ub": "https://www.urbandictionary.com/define.php?term={}",
    "!wa": "https://web.archive.org/web/*/{}",
    "!wiki": "https://en.wikipedia.org/wiki/Special:Search/{}",
    "DEFAULT": "https://startpage.com/search?q={}",
}
