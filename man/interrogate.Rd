% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/interrogate.R
\name{interrogate}
\alias{interrogate}
\title{Given an agent that has a validation plan, perform an interrogation}
\usage{
interrogate(
  agent,
  extract_failed = TRUE,
  get_first_n = NULL,
  sample_n = NULL,
  sample_frac = NULL,
  sample_limit = 5000
)
}
\arguments{
\item{agent}{An agent object of class \code{ptblank_agent} that is created with
\code{\link[=create_agent]{create_agent()}}.}

\item{extract_failed}{An option to collect rows that didn't pass a particular
validation step. The default is \code{TRUE} and further options allow for fine
control of how these rows are collected.}

\item{get_first_n}{If the option to collect non-passing rows is chosen, there
is the option here to collect the first \code{n} rows here. Supply the number of
rows to extract from the top of the non-passing rows table (the ordering of
data from the original table is retained).}

\item{sample_n}{If the option to collect non-passing rows is chosen, this
option allows for the sampling of \code{n} rows. Supply the number of rows to
sample from the non-passing rows table. If \code{n} is greater than the number
of non-passing rows, then all the rows will be returned.}

\item{sample_frac}{If the option to collect non-passing rows is chosen, this
option allows for the sampling of a fraction of those rows. Provide a
number in the range of \code{0} and \code{1}. The number of rows to return may be
extremely large (and this is especially when querying remote databases),
however, the \code{sample_limit} option will apply a hard limit to the returned
rows.}

\item{sample_limit}{A value that limits the possible number of rows returned
when sampling non-passing rows using the \code{sample_frac} option.}
}
\value{
A \code{ptblank_agent} object.
}
\description{
When the agent has all the information on what to do (i.e., a validation plan
which is a series of validation steps), the interrogation process can occur
according its plan. After that, the agent will have gathered intel, and we
can use functions like \code{\link[=get_agent_report]{get_agent_report()}} and \code{\link[=all_passed]{all_passed()}} to understand
how the interrogation went down.
}
\section{Function ID}{

6-1
}

\examples{
if (interactive()) {

# Create a simple table with two
# columns of numerical values
tbl <-
  dplyr::tibble(
    a = c(5, 7, 6, 5, 8, 7),
    b = c(7, 1, 0, 0, 0, 3)
  )

# Validate that values in column
# `a` from `tbl` are always > 5,
# using `interrogate()` carries out
# the validation plan and completes
# the whole process
agent <-
  create_agent(tbl = tbl) \%>\%
  col_vals_gt(vars(a), value = 5) \%>\%
  interrogate()

}

}
\seealso{
Other Interrogate and Report: 
\code{\link{get_agent_report}()}
}
\concept{Interrogate and Report}
