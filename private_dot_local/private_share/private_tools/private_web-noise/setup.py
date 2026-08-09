#!/usr/bin/env python3
from setuptools import setup

setup(
    name="web-noise",
    version="2.0.0",
    description="Generate realistic web traffic noise for privacy",
    author="AcidDemon",
    py_modules=["noise_generator"],
    # noise_generator cannot run without the profiles, so they ship with it
    data_files=[("share/web-noise", ["browser_profiles.json", "config.example.json"])],
    install_requires=[
        "requests",
    ],
    entry_points={
        "console_scripts": [
            "web-noise=noise_generator:main",
        ],
    },
    python_requires=">=3.6",
)
