#!/usr/bin/env python3
"""
sum_time.py

Usage:
  python3 sum_time.py path/to/file.xml
  cat file.xml | python3 sum_time.py
"""

import sys
import xml.etree.ElementTree as ET
from typing import Tuple

def sum_time_from_element(elem: ET.Element) -> Tuple[float, int]:
    total = 0.0
    count = 0
    for e in elem.iter():
        if 'time' in e.attrib:
            raw = e.attrib['time'].strip()
            # Accept both "0.123" and "0,123"
            raw = raw.replace(',', '.')
            try:
                val = float(raw)
            except ValueError:
                # skip unparseable values
                continue
            total += val
            count += 1
    return total, count

def sum_time_from_file(path: str) -> Tuple[float, int]:
    tree = ET.parse(path)
    root = tree.getroot()
    return sum_time_from_element(root)

def sum_time_from_string(xml_text: str) -> Tuple[float, int]:
    root = ET.fromstring(xml_text)
    return sum_time_from_element(root)

def main():
    if len(sys.argv) >= 2:
        path = sys.argv[1]
        total, count = sum_time_from_file(path)
    else:
        xml_text = sys.stdin.read()
        if not xml_text.strip():
            print("No input provided. Give a filename or pipe XML to stdin.", file=sys.stderr)
            sys.exit(1)
        total, count = sum_time_from_string(xml_text)

    # Print with 6 decimal places (adjust if you want different precision)
    print(f"counted {count} 'time' attributes")
    print(f"sum of time = {total:.6f}")

if __name__ == "__main__":
    main()
