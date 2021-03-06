#' botornot
#'
#' Classify users/accounts in Twitter data as bots or not bots.
#'
#' @param x Object to be classified. Can be user IDs, screen names, or
#'   data frames returned by rtweet.
#' @param fast Logical indicating whether to use the fast (lighter) model. The
#'   default (fast = FALSE) method uses the most recent 100 tweets posted by
#'   users to determine the probability of bot. The fast (fast = TRUE) method
#'   only uses users-level data, which is easier to get in large quantities from
#'   Twitter's APIS but overall less accurate.
#' @return Classifications for all users expressed as probability of whether
#'   each account is a bot.
#' @export
botornot <- function(x, fast = FALSE) UseMethod("botornot")

#' Identical to \code{botornot}
#' @rdname botornot
#' @inheritParams botornot
#' @export
tweetbotornot <- function(x, fast = FALSE) botornot(x, fast = FALSE)

#' @export
botornot.data.frame <- function(x, fast = FALSE) {
  ## store screen and user names
  su <- unique(x[, c("user_id", "screen_name")])
  if (fast) {
    ## extract features
    x <- extract_features_ntweets(x)
    ## get model
    m <- botornot_models$ntweets
  } else {
    ## extract features
    x <- extract_features_ytweets(x)
    ## get model
    m <- botornot_models$ytweets
  }
  if (!"status_text_n_chars" %in% names(x)) {
    m$var.names <- sub("^description_", "dsc_", m$var.names)
    m$var.names <- sub("^location_", "loc_", m$var.names)
    m$var.names <- sub("^status_text_", "txt_", m$var.names)
    m$var.names <- sub("^name_", "nm_", m$var.names)
  }

  ## classify data
  p <- classify_data(x, m)
  sn <- su$screen_name[match(su$user_id, x$user_id)]
  #ui <- su$user_id[match(x$user_id, ui$user_id)]
  ## return as tibble
  tibble::data_frame(
    screen_name = sn,
    user_id = x$user_id,
    prob_bot = p)
}

#' @export
botornot.factor <- function(x, fast = FALSE) {
  x <- as.character(x)
  botornot(x, fast = fast)
}

#' @export
botornot.character <- function(x, fast = FALSE) {
  ## remove NA and duplicates
  x <- x[!is.na(x) & !duplicated(x)]
  ## get most recent 100 tweets
  x <- rtweet::get_timelines(x, n = 100)
  ## pass to next method
  botornot(x, fast = fast)
}
