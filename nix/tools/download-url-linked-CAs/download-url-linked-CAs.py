#!/usr/bin/env python3

from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urljoin
import argparse
import json
import os
import re
import subprocess
import sys

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By


def get_urls(url, driver):
    driver.get(url)
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    return [urljoin(url, a['href']) for a in soup.find_all('a', href=re.compile(r'\.(crt|cert?|pem)$'))]


def is_self_signed(path):
    result = subprocess.run(['openssl', 'x509', '-in', path, '-noout', '-issuer', '-subject'], 
                            capture_output=True, text=True)
    try:
        issuer_subject = set(line.split('=', 1)[1] for line in result.stdout.strip().split('\n'))
    except IndexError:
        print(f"Error processing {path}: {result.stderr}", file=sys.stderr)
        return None
    return len(issuer_subject) == 1


def get_sri_hash(path):
    flat_hash = subprocess.run(['nix-hash', '--type', 'sha256', '--flat', path], 
                               capture_output=True, text=True).stdout.strip()
    return subprocess.run(['nix-hash', '--type', 'sha256', '--to-sri', flat_hash], 
                          capture_output=True, text=True).stdout.strip()


def process_cert_url(cert_url):
    print(f"Processing {cert_url}", file=sys.stderr)
    result = subprocess.run(['nix-prefetch-url', '--type', 'sha256', '--print-path', cert_url], 
                            capture_output=True, text=True)

    match = re.search(r'^/.*', result.stdout, re.MULTILINE)
    if not match:
        print(f"Error processing {cert_url}: {result.stderr}", file=sys.stderr)
        return None
    else:
        path = match.group(0)

        if is_self_signed(path):
            hash_value = get_sri_hash(path)
            return {'url': cert_url, 'hash': hash_value}

        return None  # Not self-signed


def main(args):
    # Set up Selenium WebDriver
    options = Options()
    if args.headless:
        options.add_argument('--headless=new')
    options.add_argument('--disable-application-cache')
    options.add_argument(f'--user-agent={args.user_agent}')
    service = Service(os.environ.get('CHROMEDRIVER_PATH'))
    driver = webdriver.Chrome(service=service, options=options)
    driver.execute_cdp_cmd('Network.setCacheDisabled', {'cacheDisabled': True})
    
    results = []
    with ThreadPoolExecutor(max_workers=args.max_workers) as executor:
        try:
            results = list(filter(None, executor.map(process_cert_url, get_urls(args.url, driver))))
        finally:
            driver.quit()
    
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Download and hash certificates linked from a URL')
    parser.add_argument('url', help='URL to scrape for certificates')
    parser.add_argument('--headless', action=argparse.BooleanOptionalAction, help='Run Chrome in headless mode', default=True)
    parser.add_argument('-n', '--max-workers', type=int, default=8, help='Maximum number of workers')
    parser.add_argument('--user-agent', help='User agent string to use', default='Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0')

    args = parser.parse_args()

    main(args)
