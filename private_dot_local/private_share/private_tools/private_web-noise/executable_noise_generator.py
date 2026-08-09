#!/usr/bin/env python3
"""
Web Traffic Noise Generator
Generates realistic random web traffic to obfuscate browsing patterns.
Supports multiple concurrent simulated users with real browser profiles.
"""

import argparse
import copy
import datetime
import json
import logging
import random
import re
import sys
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional
from urllib.parse import urljoin, urlparse

import requests

REQUIRED_CONFIG_KEYS = (
    "root_urls",
    "blacklisted_urls",
    "min_sleep",
    "max_sleep",
    "max_depth",
    "timeout",
)

# A page body larger than this is truncated rather than buffered whole; hrefs
# worth following are in the first megabytes and a crawler must never be at the
# mercy of whatever a random host decides to send.
MAX_BODY_BYTES = 2 * 1024 * 1024

# Each user is a thread. Past this the box is the bottleneck, not the noise.
MAX_USERS = 64


class NoiseGenerator:
    """Simulates a single user browsing the web with a specific browser profile"""

    def __init__(self, config: Dict, browser_profiles: List[Dict], user_id: int = 0):
        self.config = config
        self.user_id = user_id
        self.links: List[str] = []
        self.start_time: Optional[datetime.datetime] = None
        self.session = requests.Session()
        self.logger = logging.getLogger(f"User-{user_id}")
        self.request_timeout = config.get("request_timeout", 10)

        # Patterns from the config match as substrings; dead ends found while
        # crawling are exact URLs. Keeping them apart stops a dead
        # "https://site/a" from also blacklisting "https://site/a?b=1", and
        # keeps the growing half an O(1) lookup.
        self.blacklist_patterns = tuple(config["blacklisted_urls"])
        self.dead_urls = set()

        self.browser_profile = random.choice(browser_profiles)
        self.user_agent = self.browser_profile.get("user_agent")
        if not self.user_agent:
            # A profile without its own UA gets one from the config, which may
            # not match the profile's Sec-Ch-Ua and is therefore detectable.
            self.user_agent = random.choice(self.config.get("user_agents") or [])
            self.logger.debug(
                "profile %s has no user_agent, falling back to the config list",
                self.browser_profile["name"],
            )
        self.logger.info(f"Using profile: {self.browser_profile['name']}")

    class CrawlerTimedOut(Exception):
        """Raised when the specified timeout is exceeded"""

        pass

    def _get_headers(self) -> Dict[str, str]:
        headers = dict(self.browser_profile["headers"])
        if self.user_agent:
            headers["User-Agent"] = self.user_agent
        headers["Connection"] = "keep-alive"
        return {k: v for k, v in headers.items() if v is not None}

    def _fetch(self, url: str) -> bytes:
        """GET a page with the profile's headers and return at most MAX_BODY_BYTES"""
        with self.session.get(
            url,
            headers=self._get_headers(),
            timeout=self.request_timeout,
            allow_redirects=True,
            stream=True,
        ) as response:
            return response.raw.read(MAX_BODY_BYTES, decode_content=True)

    @staticmethod
    def _normalize_link(link: str, root_url: str) -> Optional[str]:
        """Normalizes links to absolute URLs"""
        try:
            parsed_url = urlparse(link)
        except ValueError:
            return None

        parsed_root_url = urlparse(root_url)

        # '//' means keep the current protocol
        if link.startswith("//"):
            return f"{parsed_root_url.scheme}://{parsed_url.netloc}{parsed_url.path}"

        if not parsed_url.scheme:
            return urljoin(root_url, link)

        return link

    @staticmethod
    def _is_valid_url(url: str) -> bool:
        regex = re.compile(
            r'^(?:http|ftp)s?://'
            r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'
            r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
            r'(?::\d+)?'
            r'(?:/?|[/?]\S+)$', re.IGNORECASE)
        return re.match(regex, url) is not None

    def _is_blacklisted(self, url: str) -> bool:
        if url in self.dead_urls:
            return True
        return any(pattern in url for pattern in self.blacklist_patterns)

    def _should_accept_url(self, url: Optional[str]) -> bool:
        return bool(url) and self._is_valid_url(url) and not self._is_blacklisted(url)

    def _extract_urls(self, body: bytes, root_url: str) -> List[str]:
        pattern = r"href=[\"'](?!#)(.*?)[\"'].*?"
        # decode, not str(): str(b'...') yields the repr, so every \n and \xNN
        # would be matched as literal backslash text
        urls = re.findall(pattern, body.decode("utf-8", "replace"))

        normalized_urls = [self._normalize_link(url, root_url) for url in urls]
        return [url for url in normalized_urls if self._should_accept_url(url)]

    def _remove_and_blacklist(self, link: str):
        self.dead_urls.add(link)
        if link in self.links:
            self.links.remove(link)

    def _random_sleep(self):
        base_sleep = random.uniform(self.config["min_sleep"], self.config["max_sleep"])

        if random.random() < 0.1:
            # reading an article, or looking away
            base_sleep *= random.uniform(2, 5)
        elif random.random() < 0.05:
            # scanning through pages
            base_sleep *= 0.5

        time.sleep(base_sleep)

    def _browse_from_links(self, max_depth: int):
        """Iteratively browse links (non-recursive to avoid stack overflow)"""
        depth = 0

        while depth < max_depth and self.links:
            if self._is_timeout_reached():
                raise self.CrawlerTimedOut

            random_link = random.choice(self.links)
            try:
                self.logger.info(f"Visiting (depth {depth}): {random_link[:80]}...")
                sub_links = self._extract_urls(self._fetch(random_link), random_link)

                self._random_sleep()

                if sub_links:
                    # a real person does not follow every link on a page
                    num_links = min(len(sub_links), random.randint(5, 25))
                    self.links = random.sample(sub_links, num_links)
                    depth += 1
                else:
                    self._remove_and_blacklist(random_link)

            except requests.exceptions.Timeout:
                self.logger.debug(f"Timeout on {random_link[:60]}")
                self._remove_and_blacklist(random_link)
            except requests.exceptions.RequestException as e:
                self.logger.debug(f"Request error on {random_link[:60]}: {e}")
                self._remove_and_blacklist(random_link)
            except MemoryError:
                self.logger.warning(f"Memory error on {random_link[:60]}, skipping")
                self._remove_and_blacklist(random_link)
            except Exception as e:
                self.logger.warning(
                    f"Unexpected error on {random_link[:60]}: {type(e).__name__}: {e}"
                )
                self._remove_and_blacklist(random_link)

    def _is_timeout_reached(self) -> bool:
        # 0, false and null all mean "run until interrupted"
        if not self.config["timeout"]:
            return False
        end_time = self.start_time + datetime.timedelta(seconds=self.config["timeout"])
        return datetime.datetime.now() >= end_time

    def run(self):
        self.start_time = datetime.datetime.now()
        self.logger.info("Starting noise generation")

        try:
            while True:
                if self._is_timeout_reached():
                    self.logger.info("Timeout reached, stopping")
                    break

                url = random.choice(self.config["root_urls"])
                try:
                    self.logger.info(f"Starting from root: {url}")
                    self.links = self._extract_urls(self._fetch(url), url)

                    if self.links:
                        self.logger.debug(f"Found {len(self.links)} links")
                        self._browse_from_links(self.config["max_depth"])
                    else:
                        self.logger.debug(f"No links found at {url}")

                except requests.exceptions.RequestException as e:
                    self.logger.warning(f"Error connecting to {url}: {e}")

                except self.CrawlerTimedOut:
                    self.logger.info("Timeout exceeded, exiting")
                    break

                time.sleep(random.uniform(2, 8))
        finally:
            self.session.close()


class MultiUserNoiseGenerator:
    """Manages multiple concurrent simulated users"""

    def __init__(self, config: Dict, browser_profiles: List[Dict], num_users: int = 1):
        self.config = config
        self.browser_profiles = browser_profiles
        self.num_users = num_users
        self.threads: List[threading.Thread] = []
        self.logger = logging.getLogger("MultiUser")

    def _user_worker(self, user_id: int):
        # a copy per user, so one user's crawl state cannot race another's
        user = NoiseGenerator(copy.deepcopy(self.config), self.browser_profiles, user_id)
        user.run()

    def run(self):
        self.logger.info(f"Starting {self.num_users} simulated user(s)")

        for i in range(self.num_users):
            thread = threading.Thread(
                target=self._user_worker,
                args=(i,),
                daemon=True,
                name=f"User-{i}"
            )
            self.threads.append(thread)
            thread.start()

            if i < self.num_users - 1:
                time.sleep(random.uniform(2, 5))

        self.logger.info("All users started")

        try:
            for thread in self.threads:
                thread.join()
        except KeyboardInterrupt:
            self.logger.info("Interrupted, waiting for threads to finish...")
            for thread in self.threads:
                thread.join(timeout=5)


def load_json_file(file_path: Path) -> Dict:
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def find_profiles() -> Optional[Path]:
    """Locate browser_profiles.json for either install layout"""
    candidates = (
        # resolve() first: run through a symlink, __file__ is the symlink and its
        # parent is wherever that link lives, not the install directory
        Path(__file__).resolve().parent / 'browser_profiles.json',
        Path(sys.prefix) / 'share' / 'web-noise' / 'browser_profiles.json',
    )
    return next((path for path in candidates if path.exists()), None)


def main():
    parser = argparse.ArgumentParser(
        description='Generate web traffic noise for privacy',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '--log', '-l',
        type=str,
        choices=['debug', 'info', 'warning', 'error'],
        help='Logging level',
        default='info'
    )
    parser.add_argument(
        '--config', '-c',
        required=True,
        type=Path,
        help='Path to config JSON file'
    )
    parser.add_argument(
        '--profiles', '-p',
        type=Path,
        help='Path to browser profiles JSON file',
        default=None
    )
    parser.add_argument(
        '--timeout', '-t',
        type=int,
        help='Duration to run (seconds), 0 for infinite',
        default=None
    )
    parser.add_argument(
        '--users', '-u',
        type=int,
        help='Number of concurrent simulated users',
        default=1
    )

    args = parser.parse_args()

    if not 1 <= args.users <= MAX_USERS:
        parser.error(f"--users must be between 1 and {MAX_USERS}")

    level = getattr(logging, args.log.upper())
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)-12s - %(levelname)-8s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    if not args.config.exists():
        logging.error(f"Config file not found: {args.config}")
        return 1

    config = load_json_file(args.config)
    missing = [key for key in REQUIRED_CONFIG_KEYS if key not in config]
    if missing:
        logging.error(f"Config {args.config} is missing: {', '.join(missing)}")
        return 1

    if args.profiles:
        profiles_path = args.profiles
        if not profiles_path.exists():
            logging.error(f"Browser profiles file not found: {profiles_path}")
            return 1
    else:
        profiles_path = find_profiles()
        if profiles_path is None:
            logging.error(
                "browser_profiles.json not found next to the module or in "
                f"{Path(sys.prefix) / 'share' / 'web-noise'}; pass --profiles"
            )
            return 1

    profiles_data = load_json_file(profiles_path)
    browser_profiles = profiles_data['profiles']

    logging.info(f"Loaded {len(browser_profiles)} browser profiles")

    if args.timeout is not None:
        config['timeout'] = args.timeout

    generator = MultiUserNoiseGenerator(config, browser_profiles, args.users)
    generator.run()

    logging.info("Noise generation complete")
    return 0


if __name__ == '__main__':
    sys.exit(main())
