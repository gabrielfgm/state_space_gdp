#!/usr/bin/env bash

pandoc $1 --webtex='https://latex.codecogs.com/png.latex?' -t html | pandoc -f html -o README.md