#!/usr/bin/env bash

pandoc README.tex.md --webtex -t html | pandoc -f html -o README.md