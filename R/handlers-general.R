#' `initialize` handler
#'
#' Handler to the `initialize` [Request].
#'
#' @keywords internal
on_initialize <- function(self, id, params) {
    logger$info("initialization config: ", params)
    self$processId <- params$processId
    self$rootUri <- params$rootUri
    self$rootPath <- path_from_uri(self$rootUri)
    self$initializationOptions <- params$initializationOptions
    self$ClientCapabilities <- params$capabilities
    ServerCapabilities <- merge_list(
        ServerCapabilities,
        getOption("languageserver.server_capabilities"))
    self$deliver(Response$new(id = id, result = list(capabilities = ServerCapabilities)))
}

#' `initialized` handler
#'
#' Handler to the `initialized` [Notification].
#'
#' @keywords internal
on_initialized <- function(self, params) {
    logger$info("on_initialized")
    project_root <- self$rootPath
    if (length(project_root) && is_package(project_root)) {
        source_dir <- file.path(project_root, "R")
        files <- list.files(source_dir)
        for (f in files) {
            logger$info("load ", f)
            path <- file.path(source_dir, f)
            uri <- path_to_uri(path)
            doc <- Document$new(uri, NULL, stringi::stri_read_lines(path))
            self$workspace$documents$set(uri, doc)
            self$text_sync(uri, document = doc, parse = TRUE)
        }
        deps <- tryCatch(desc::desc_get_deps(project_root), error = function(e) NULL)
        if (!is.null(deps)) {
            packages <- Filter(function(x) x != "R", deps$package[deps$type == "Depends"])
            self$workspace$load_packages(packages)
        }
    }
    # TODO: result lint result of the package
    # lint_result <- lintr::lint_package(rootPath)
}

#' `shutdown` request handler
#'
#' Handler to the `shutdown` [Request].
#' @keywords internal
on_shutdown <- function(self, id, params) {
    self$exit_flag <- TRUE
    self$deliver(Response$new(id = id, result = list()))
}


#' `exit` notification handler
#'
#' Handler to the `exit` [Notification].
#' @keywords internal
on_exit <- function(self, params) {
    self$exit_flag <- TRUE
}

#' `cancel` request notification handler
#'
#' Handler to the `cancelRequest` [Notification].
#' @keywords internal
cancel_request <- function(self, params) {

}
