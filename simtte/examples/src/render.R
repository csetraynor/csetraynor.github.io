#!/usr/bin/env Rscript
# Render the simtte examples published under simtte/examples/.
#
# Usage, from the repository root:
#   R_LIBS=<lib with the simtte version to document> \
#     Rscript simtte/examples/src/render.R <simtte source dir> <cox-simulation dir> "<version label>"
#
# The vignettes are copied from <simtte source dir>/vignettes and the Cox
# scripts from <cox-simulation dir>; neither folder is modified. Each page is a
# self-contained HTML file written to simtte/examples/.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3)
pkg_src <- normalizePath(args[[1]], mustWork = TRUE)
cox_dir <- normalizePath(args[[2]], mustWork = TRUE)
label <- args[[3]]

src_dir <- normalizePath("simtte/examples/src", mustWork = TRUE)
out_dir <- normalizePath("simtte/examples", mustWork = TRUE)

build <- file.path(tempdir(), "simtte-site")
dir.create(build, showWarnings = FALSE)

library(simtte)
options(rmarkdown.html_vignette.check_title = FALSE)
message("Rendering with simtte ", packageVersion("simtte"),
        " from ", find.package("simtte"))

footer <- file.path(build, "footer.html")
writeLines(sprintf(
  '<p class="site-footer">Rendered with simtte %s on %s.</p>',
  label, format(Sys.Date(), "%d %B %Y")
), footer)

page_format <- function() {
  rmarkdown::html_vignette(
    css = c(
      system.file("rmarkdown/templates/html_vignette/resources/vignette.css",
                  package = "rmarkdown"),
      file.path(src_dir, "examples.css")
    ),
    includes = rmarkdown::includes(
      before_body = file.path(src_dir, "nav.html"),
      after_body = footer
    )
  )
}

render_page <- function(input) {
  rmarkdown::render(input, output_format = page_format(), output_dir = out_dir,
                    envir = new.env(), quiet = TRUE)
}

for (v in c("introduction", "pkpd-time-to-event", "censoring-and-assessment")) {
  invisible(file.copy(file.path(pkg_src, "vignettes", paste0(v, ".Rmd")),
                      build, overwrite = TRUE))
  render_page(file.path(build, paste0(v, ".Rmd")))
}

Sys.setenv(COX_DIR = cox_dir)
invisible(file.copy(file.path(src_dir, "cox-simulation.Rmd"), build,
                    overwrite = TRUE))
render_page(file.path(build, "cox-simulation.Rmd"))
