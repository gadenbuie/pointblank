% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tbl_store.R
\name{tbl_store}
\alias{tbl_store}
\title{Define a store of tables with table-prep formulas: a table store}
\usage{
tbl_store(..., .list = list2(...))
}
\arguments{
\item{...}{Expressions that contain table-prep formulas and table names for
data retrieval. Two-sided formulas (e.g, \verb{<LHS> ~ <RHS>}) are to be used,
where the left-hand side is a given name and the right-hand is the portion
that is is used to obtain the table.}

\item{.list}{Allows for the use of a list as an input alternative to \code{...}.}
}
\value{
A \code{tbl_store} object that contains table-prep formulas.
}
\description{
It can be useful to set up all the data sources you need and just draw from
them when necessary. This upfront configuration with \code{tbl_store()} lets us
define the methods for obtaining tabular data from mixed sources (e.g.,
database tables, tables generated from flat files, etc.) and provide names
for these data preparation procedures. Then we have a convenient way to
access the materialized tables with \code{\link[=tbl_get]{tbl_get()}}, or, the table-prep formulas
with \code{\link[=tbl_source]{tbl_source()}}. Table-prep formulas can be as simple as getting a table
from a location, or, it can involve as much mutation as is necessary (imagine
procuring several mutated variations of the same source table, generating a
table from multiple sources, or pre-filtering a database table according to
the system time). Another nice aspect of organizing table-prep formulas in a
single object is supplying it to the \code{read_fn} argument of \code{\link[=create_agent]{create_agent()}}
or \code{\link[=create_informant]{create_informant()}} via \code{$} notation (e.g, \verb{create_agent(read_fn = <tbl_store>$<name>)}) or with \code{\link[=tbl_source]{tbl_source()}} (e.g., \verb{create_agent(read_fn = ~ tbl_source("<name>", <tbl_store>))}).
}
\section{YAML}{

A \strong{pointblank} table store can be written to YAML with \code{\link[=yaml_write]{yaml_write()}} and
the resulting YAML can be used in several ways. The ideal scenario is to have
pointblank agents and informants also in YAML form. This way the agent and
informant can refer to the table store YAML (via \code{\link[=tbl_source]{tbl_source()}}), and, the
processing of both agents and informants can be performed with
\code{\link[=yaml_agent_interrogate]{yaml_agent_interrogate()}} and \code{\link[=yaml_informant_incorporate]{yaml_informant_incorporate()}}. With the
following R code, a table store with two table-prep formulas is generated and
written to YAML (if no filename is given then the YAML is written to
\code{"tbl_store.yml"}).\preformatted{# R statement for generating the "tbl_store.yml" file
tbl_store(
  tbl_duckdb ~ db_tbl(small_table, dbname = ":memory:", dbtype = "duckdb"),
  sml_table_high ~ small_table \%>\% dplyr::filter(f == "high")
) \%>\%
  yaml_write()

# YAML representation ("tbl_store.yml")
tbls:
  tbl_duckdb: ~ db_tbl(small_table, dbname = ":memory:", dbtype = "duckdb")
  sml_table_high: ~ small_table \%>\% dplyr::filter(f == "high")
}

This is useful when you want to get fresh pulls of prepared data from a
source materialized in an R session (with the \code{\link[=tbl_get]{tbl_get()}} function. For
example, the \code{sml_table_high} table can be obtained by using
\code{tbl_get("sml_table_high", "tbl_store.yml")}. To get an agent to check this
prepared data periodically, then the following example with \code{\link[=tbl_source]{tbl_source()}}
will be useful:\preformatted{# Generate agent that checks `sml_table_high`, write it to YAML
create_agent(
  read_fn = ~ tbl_source("sml_table_high", "tbl_store.yml"),
  label = "An example that uses a table store.",
  actions = action_levels(warn_at = 0.10)
) \%>\% 
  col_exists(vars(date, date_time)) \%>\%
  write_yaml()
  
# YAML representation ("agent-sml_table_high.yml")
read_fn: ~ tbl_source("sml_table_high", "tbl_store.yml")
tbl_name: sml_table_high
label: An example that uses a table store.
actions:
  warn_fraction: 0.1
locale: en
steps:
  - col_exists:
    columns: vars(date, date_time)
}

Now, whenever the \code{sml_table_high} table needs to be validated, it can be
done with \code{\link[=yaml_agent_interrogate]{yaml_agent_interrogate()}} (e.g.,
\code{yaml_agent_interrogate("agent-sml_table_high.yml")}).
}

\section{Function ID}{

1-8
}

\examples{
if (interactive()) {

# Define a `tbl_store` object by adding
# table-prep formulas inside the
# `tbl_store()` call
tbls <- 
  tbl_store(
    small_table_duck ~ db_tbl(
      table = small_table,
      dbname = ":memory:",
      dbtype = "duckdb"
    ),
    ~ db_tbl(
      table = "rna",
      dbname = "pfmegrnargs",
      dbtype = "postgres",
      host = "hh-pgsql-public.ebi.ac.uk",
      port = 5432,
      user = I("reader"),
      password = I("NWDMCE5xdipIjRrp")
    ),
    all_revenue ~ db_tbl(
      table = file_tbl(
        file = from_github(
          file = "all_revenue_large.rds",
          repo = "rich-iannone/intendo",
          subdir = "data-large"
        )
      ),
      dbname = ":memory:",
      dbtype = "duckdb"
    ),
    sml_table ~ pointblank::small_table
  )

# Once this object is available, you
# can check that the table of interest
# is produced to your specification with
# the `tbl_get()` function
tbl_get(
  tbl = "small_table_duck",
  store = tbls
)

# Another simpler way to get the same
# table materialized is by using `$` to
# get the entry of choice for `tbl_get()`
tbls$small_table_duck \%>\% tbl_get()

# Creating an agent is easy when all
# table-prep formulas are encapsulated
# in a `tbl_store` object; use `$` 
# notation to pass the appropriate
# procedure for reading a table to the
# `read_fn` argument
agent_1 <-
  create_agent(
    read_fn = tbls$small_table_duck
  )
  
# There are other ways to use the
# table store to assign a target table
# to an agent, like using the
# `tbl_source()` function
agent_2 <-
  create_agent(
    read_fn = ~ tbl_source(
      tbl = "small_table_duck",
      store = tbls
      )
  )

# The table store can be moved to
# YAML with `yaml_write` and the
# `tbl_source()` call could then
# refer to that on-disk table store;
# let's do that YAML conversion
yaml_write(tbls)

# The above writes the `tbl_store.yml`
# file (by not providing a `filename`
# this default filename is chosen);
# next, modify the `tbl_source()`
# so that `store` refer to the YAML
# file
agent_3 <-
  create_agent(
    read_fn = ~ tbl_source(
      tbl = "small_table_duck",
      store = "tbl_store.yml"
    )
  )

}

}
\seealso{
Other Planning and Prep: 
\code{\link{action_levels}()},
\code{\link{create_agent}()},
\code{\link{create_informant}()},
\code{\link{db_tbl}()},
\code{\link{draft_validation}()},
\code{\link{file_tbl}()},
\code{\link{scan_data}()},
\code{\link{tbl_get}()},
\code{\link{tbl_source}()},
\code{\link{validate_rmd}()}
}
\concept{Planning and Prep}
