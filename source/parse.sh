#!/bin/bash

cd 我的笔记
/Applications/pandoc-2.8.0.1/bin/pandoc -s -t rst $1.md -o $1.rst
