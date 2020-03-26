#!/usr/bin/env Rscript

rmarkdown::render("to_compile_readme.md", 
                  rmarkdown::md_document(variant = "gfm"), 
                  output_file = "README.md")