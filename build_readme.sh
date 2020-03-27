#!/usr/bin/env bash

pandoc README.tex.md --webtex='https://latex.codecogs.com/png.latex?' -t html | pandoc -f html -o README.md