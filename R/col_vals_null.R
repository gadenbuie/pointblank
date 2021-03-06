#
#                _         _    _      _                _    
#               (_)       | |  | |    | |              | |   
#  _ __    ___   _  _ __  | |_ | |__  | |  __ _  _ __  | | __
# | '_ \  / _ \ | || '_ \ | __|| '_ \ | | / _` || '_ \ | |/ /
# | |_) || (_) || || | | || |_ | |_) || || (_| || | | ||   < 
# | .__/  \___/ |_||_| |_| \__||_.__/ |_| \__,_||_| |_||_|\_\
# | |                                                        
# |_|                                                        
# 
# This file is part of the 'rich-iannone/pointblank' package.
# 
# (c) Richard Iannone <riannone@me.com>
# 
# For full copyright and license information, please look at
# https://rich-iannone.github.io/pointblank/LICENSE.html
#


#' Are column data `NULL`/`NA`?
#'
#' @description
#' The `col_vals_null()` validation function, the `expect_col_vals_null()`
#' expectation function, and the `test_col_vals_null()` test function all check
#' whether column values in a table are `NA` values or, in the database context,
#' `NULL` values. The validation function can be used directly on a data table
#' or with an *agent* object (technically, a `ptblank_agent` object) whereas the
#' expectation and test functions can only be used with a data table. The types
#' of data tables that can be used include data frames, tibbles, database tables
#' (`tbl_dbi`), and Spark DataFrames (`tbl_spark`). Each validation step or
#' expectation will operate over the number of test units that is equal to the
#' number of rows in the table (after any `preconditions` have been applied).
#'
#' @section Column Names:
#' If providing multiple column names, the result will be an expansion of
#' validation steps to that number of column names (e.g., `vars(col_a, col_b)`
#' will result in the entry of two validation steps). Aside from column names in
#' quotes and in `vars()`, **tidyselect** helper functions are available for
#' specifying columns. They are: `starts_with()`, `ends_with()`, `contains()`,
#' `matches()`, and `everything()`.
#' 
#' @section Preconditions:
#' Providing expressions as `preconditions` means **pointblank** will preprocess
#' the target table table during interrogation as a preparatory step. It might
#' happen that a particular validation requires a calculated column, some
#' filtering of rows, or the addition of columns via a join, etc. Especially for
#' an *agent*-based report this can be advantageous since we can develop a large
#' validation plan with a single target table and make minor adjustments to it,
#' as needed, along the way.
#'
#' The table mutation is totally isolated in scope to the validation step(s)
#' where `preconditions` is used. Using **dplyr** code is suggested here since
#' the statements can be translated to SQL if necessary (i.e., if the target
#' table resides in a database). The code is most easily supplied as a one-sided
#' **R** formula (using a leading `~`). In the formula representation, the `.`
#' serves as the input data table to be transformed (e.g., `~ . %>%
#' dplyr::mutate(col_b = col_a + 10)`). Alternatively, a function could instead
#' be supplied (e.g., `function(x) dplyr::mutate(x, col_b = col_a + 10)`).
#' 
#' @section Segments:
#' By using the `segments` argument, it's possible to define a particular
#' validation with segments (or row slices) of the target table. An optional
#' expression or set of expressions that serve to segment the target table by
#' column values. Each expression can be given in one of two ways: (1) as column
#' names, or (2) as a two-sided formula where the LHS holds a column name and
#' the RHS contains the column values to segment on.
#' 
#' As an example of the first type of expression that can be used,
#' `vars(a_column)` will segment the target table in however many unique values
#' are present in the column called `a_column`. This is great if every unique
#' value in a particular column (like different locations, or different dates)
#' requires it's own repeating validation.
#'
#' With a formula, we can be more selective with which column values should be
#' used for segmentation. Using `a_column ~ c("group_1", "group_2")` will
#' attempt to obtain two segments where one is a slice of data where the value
#' `"group_1"` exists in the column named `"a_column"`, and, the other is a
#' slice where `"group_2"` exists in the same column. Each group of rows
#' resolved from the formula will result in a separate validation step.
#'
#' If there are multiple `columns` specified then the potential number of
#' validation steps will be `m` columns multiplied by `n` segments resolved.
#'
#' Segmentation will always occur after `preconditions` (i.e., statements that
#' mutate the target table), if any, are applied. With this type of one-two
#' combo, it's possible to generate labels for segmentation using an expression
#' for `preconditions` and refer to those labels in `segments` without having to
#' generate a separate version of the target table.
#' 
#' @section Actions:
#' Often, we will want to specify `actions` for the validation. This argument,
#' present in every validation function, takes a specially-crafted list
#' object that is best produced by the [action_levels()] function. Read that
#' function's documentation for the lowdown on how to create reactions to
#' above-threshold failure levels in validation. The basic gist is that you'll
#' want at least a single threshold level (specified as either the fraction of
#' test units failed, or, an absolute value), often using the `warn_at`
#' argument. This is especially true when `x` is a table object because,
#' otherwise, nothing happens. For the `col_vals_*()`-type functions, using 
#' `action_levels(warn_at = 0.25)` or `action_levels(stop_at = 0.25)` are good
#' choices depending on the situation (the first produces a warning when a
#' quarter of the total test units fails, the other `stop()`s at the same
#' threshold level).
#' 
#' @section Briefs:
#' Want to describe this validation step in some detail? Keep in mind that this
#' is only useful if `x` is an *agent*. If that's the case, `brief` the agent
#' with some text that fits. Don't worry if you don't want to do it. The
#' *autobrief* protocol is kicked in when `brief = NULL` and a simple brief will
#' then be automatically generated.
#' 
#' @section YAML:
#' A **pointblank** agent can be written to YAML with [yaml_write()] and the
#' resulting YAML can be used to regenerate an agent (with [yaml_read_agent()])
#' or interrogate the target table (via [yaml_agent_interrogate()]). When
#' `col_vals_null()` is represented in YAML (under the top-level `steps` key as
#' a list member), the syntax closely follows the signature of the validation
#' function. Here is an example of how a complex call of `col_vals_null()` as a
#' validation step is expressed in R code and in the corresponding YAML
#' representation.
#' 
#' ```
#' # R statement
#' agent %>% 
#'   col_vals_null(
#'     vars(a),
#'     preconditions = ~ . %>% dplyr::filter(a < 10),
#'     segments = b ~ c("group_1", "group_2"),
#'     actions = action_levels(warn_at = 0.1, stop_at = 0.2),
#'     label = "The `col_vals_null()` step.",
#'     active = FALSE
#'   )
#' 
#' # YAML representation
#' steps:
#' - col_vals_null:
#'     columns: vars(a)
#'     preconditions: ~. %>% dplyr::filter(a < 10)
#'     segments: b ~ c("group_1", "group_2")
#'     actions:
#'       warn_fraction: 0.1
#'       stop_fraction: 0.2
#'     label: The `col_vals_null()` step.
#'     active: false
#' ```
#' 
#' In practice, both of these will often be shorter as only the `columns`,
#' argument requires a value. Arguments with default values won't be written to
#' YAML when using [yaml_write()] (though it is acceptable to include them with
#' their default when generating the YAML by other means). It is also possible
#' to preview the transformation of an agent to YAML without any writing to disk
#' by using the [yaml_agent_string()] function.
#'
#' @inheritParams col_vals_gt
#' 
#' @return For the validation function, the return value is either a
#'   `ptblank_agent` object or a table object (depending on whether an agent
#'   object or a table was passed to `x`). The expectation function invisibly
#'   returns its input but, in the context of testing data, the function is
#'   called primarily for its potential side-effects (e.g., signaling failure).
#'   The test function returns a logical value.
#'   
#' @examples
#' # For all examples here, we'll use
#' # a simple table with four columns:
#' # `a`, `b`, `c`, and `d`
#' tbl <-
#'   dplyr::tibble(
#'     a = c( 5,  7,  6,  5,  8),
#'     b = c( 7,  1,  0,  0,  0),
#'     c = c(NA, NA, NA, NA, NA),
#'     d = c(35, 23, NA, NA, NA)
#'   )
#'   
#' tbl
#'   
#' # A: Using an `agent` with validation
#' #    functions and then `interrogate()`
#' 
#' # Validate that all values in column
#' # `c` are NA (they would be NULL in a
#' # database context, which isn't the
#' # case here)
#' agent <-
#'   create_agent(tbl) %>%
#'   col_vals_null(vars(c)) %>%
#'   interrogate()
#' 
#' # Determine if this validation
#' # had no failing test units (there
#' # are 5 test units, one for each row)
#' all_passed(agent)
#' 
#' # Calling `agent` in the console
#' # prints the agent's report; but we
#' # can get a `gt_tbl` object directly
#' # with `get_agent_report(agent)`
#' 
#' # B: Using the validation function
#' #    directly on the data (no `agent`)
#' 
#' # This way of using validation functions
#' # acts as a data filter: data is passed
#' # through but should `stop()` if there
#' # is a single test unit failing; the
#' # behavior of side effects can be
#' # customized with the `actions` option
#' tbl %>%
#'   col_vals_null(vars(c)) %>%
#'   dplyr::pull(c)
#'
#' # C: Using the expectation function
#' 
#' # With the `expect_*()` form, we would
#' # typically perform one validation at a
#' # time; this is primarily used in
#' # testthat tests
#' expect_col_vals_null(tbl, vars(c))
#' 
#' # D: Using the test function
#' 
#' # With the `test_*()` form, we should
#' # get a single logical value returned
#' # to us
#' tbl %>% test_col_vals_null(vars(c))
#' 
#' @family validation functions
#' @section Function ID:
#' 2-15
#' 
#' @seealso The analogue to this function: [col_vals_not_null()].
#' 
#' @name col_vals_null
NULL

#' @rdname col_vals_null
#' @import rlang
#' @export
col_vals_null <- function(x,
                          columns,
                          preconditions = NULL,
                          segments = NULL,
                          actions = NULL,
                          step_id = NULL,
                          label = NULL,
                          brief = NULL,
                          active = TRUE) {
  
  values <- NULL
  
  # Get `columns` as a label
  columns_expr <- 
    rlang::as_label(rlang::quo(!!enquo(columns))) %>%
    gsub("^\"|\"$", "", .)
  
  # Capture the `columns` expression
  columns <- rlang::enquo(columns)
  
  # Resolve the columns based on the expression
  columns <- resolve_columns(x = x, var_expr = columns, preconditions)
  
  # Resolve segments into list
  segments_list <-
    resolve_segments(
      x = x,
      seg_expr = segments,
      preconditions = preconditions
    )
  
  if (is_a_table_object(x)) {
    
    secret_agent <-
      create_agent(x, label = "::QUIET::") %>%
      col_vals_null(
        columns = columns,
        preconditions = preconditions,
        segments = segments,
        label = label,
        brief = brief,
        actions = prime_actions(actions),
        active = active
      ) %>%
      interrogate()
    
    return(x)
  }
  
  agent <- x
  
  if (is.null(brief)) {
    
    brief <-
      generate_autobriefs(
        agent = agent,
        columns = columns,
        preconditions = preconditions,
        values = values,
        assertion_type = "col_vals_null"
      )
  }
  
  # Normalize any provided `step_id` value(s)
  step_id <- normalize_step_id(step_id, columns, agent)
  
  # Get the next step number for the `validation_set` tibble
  i_o <- get_next_validation_set_row(agent)
  
  # Check `step_id` value(s) against all other `step_id`
  # values in earlier validation steps
  check_step_id_duplicates(step_id, agent)
  
  # Add one or more validation steps based on the
  # length of the `columns` variable
  for (i in seq_along(columns)) {
    for (j in seq_along(segments_list)) {
      
      seg_col <- names(segments_list[j])
      seg_val <- unname(unlist(segments_list[j]))
      
      agent <-
        create_validation_step(
          agent = agent,
          assertion_type = "col_vals_null",
          i_o = i_o,
          columns_expr = columns_expr,
          column = columns[i],
          preconditions = preconditions,
          seg_expr = segments,
          seg_col = seg_col,
          seg_val = seg_val,
          actions = covert_actions(actions, agent),
          step_id = step_id[i],
          label = label,
          brief = brief[i],
          active = active
        )
    }
  }

  agent
}

#' @rdname col_vals_null
#' @import rlang
#' @export
expect_col_vals_null <- function(object,
                                 columns,
                                 preconditions = NULL,
                                 threshold = 1) {
  
  fn_name <- "expect_col_vals_null"
  
  vs <- 
    create_agent(tbl = object, label = "::QUIET::") %>%
    col_vals_null(
      columns = {{ columns }},
      preconditions = {{ preconditions }},
      actions = action_levels(notify_at = threshold)
    ) %>%
    interrogate() %>%
    .$validation_set
  
  x <- vs$notify %>% all()
  
  threshold_type <- get_threshold_type(threshold = threshold)
  
  if (threshold_type == "proportional") {
    failed_amount <- vs$f_failed
  } else {
    failed_amount <- vs$n_failed
  }
  
  if (inherits(vs$capture_stack[[1]]$warning, "simpleWarning")) {
    warning(conditionMessage(vs$capture_stack[[1]]$warning))
  }
  if (inherits(vs$capture_stack[[1]]$error, "simpleError")) {
    stop(conditionMessage(vs$capture_stack[[1]]$error))
  }
  
  act <- testthat::quasi_label(enquo(x), arg = "object")
  
  column_text <- prep_column_text(vs$column[[1]])
  
  testthat::expect(
    ok = identical(!as.vector(act$val), TRUE),
    failure_message = glue::glue(
      failure_message_gluestring(
        fn_name = fn_name, lang = "en"
      )
    )
  )
  
  act$val <- object
  
  invisible(act$val)
}

#' @rdname col_vals_null
#' @import rlang
#' @export
test_col_vals_null <- function(object,
                               columns,
                               preconditions = NULL,
                               threshold = 1) {
  
  vs <- 
    create_agent(tbl = object, label = "::QUIET::") %>%
    col_vals_null(
      columns = {{ columns }},
      preconditions = {{ preconditions }},
      actions = action_levels(notify_at = threshold)
    ) %>%
    interrogate() %>%
    .$validation_set
  
  if (inherits(vs$capture_stack[[1]]$warning, "simpleWarning")) {
    warning(conditionMessage(vs$capture_stack[[1]]$warning))
  }
  if (inherits(vs$capture_stack[[1]]$error, "simpleError")) {
    stop(conditionMessage(vs$capture_stack[[1]]$error))
  }
  
  all(!vs$notify)
}
