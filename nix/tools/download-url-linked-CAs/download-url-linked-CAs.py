#!/usr/bin/env python3
import os
import sys
import re
import subprocess
import json
from urllib.parse import urljoin
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup

def get_urls(url, driver):
    driver.get(url)
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    return [urljoin(url, a['href']) for a in soup.find_all('a', href=re.compile(r'\.(crt|cert?|pem)$'))]

def is_self_signed(path):
    result = subprocess.run(['openssl', 'x509', '-in', path, '-noout', '-issuer', '-subject'], 
                            capture_output=True, text=True)
    issuer_subject = set(line.split('=', 1)[1] for line in result.stdout.strip().split('\n'))
    return len(issuer_subject) == 1

def get_sri_hash(path):
    flat_hash = subprocess.run(['nix-hash', '--type', 'sha256', '--flat', path], 
                               capture_output=True, text=True).stdout.strip()
    return subprocess.run(['nix-hash', '--type', 'sha256', '--to-sri', flat_hash], 
                          capture_output=True, text=True).stdout.strip()

def main(url):
    # Set up Selenium WebDriver
    options = Options()
    options.add_argument('--headless=new')
    service = Service(os.environ.get('CHROMEDRIVER_PATH'))
    driver = webdriver.Chrome(service=service, options=options)
    
    results = []
    try:
        for cert_url in get_urls(url, driver):
            try:
                result = subprocess.run(['nix-prefetch-url', '--type', 'sha256', '--print-path', cert_url], 
                                        capture_output=True, text=True)
                path = re.search(r'^/.*', result.stdout, re.MULTILINE).group(0)
                
                if is_self_signed(path):
                    hash_value = get_sri_hash(path)
                    results.append({'url': cert_url, 'hash': hash_value})
            except Exception as e:
                print(f"Error processing {cert_url}: {e}", file=sys.stderr)
    finally:
        driver.quit()
    
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <URL>")
        sys.exit(1)
    main(sys.argv[1])
