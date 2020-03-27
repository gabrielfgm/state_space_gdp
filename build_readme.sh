#!/usr/bin/env bash

pandoc README.tex.md --webtex='https://latex.codecogs.com/png.latex?%5Cdpi{300}' -t html | pandoc -f html -o README.md