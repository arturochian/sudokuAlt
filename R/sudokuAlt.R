##' Construct a Sudoku Game Object
##'
##' Coerce an object to one that can be used as a sudoku game.
##' IMPORTANT: games are represented as n^2xn^2 character matrices,
##' using 1-9 for n=2 or 3, and LETTERS[1:(n^2)] for n = 4 or 5.
##' @title Generic Sudoku Game Constructor
##' @param x an n^2 x n^2 matrix object to represent the game
##' @param ... Other additional arguments (currently ignored)
##' @return An object of class 'sudoku'
##' @export as.sudoku
##' @rdname as.sudoku
##' @examples
##' M <- as.sudoku(matrix("", 16, 16))
##' M[1:4, 1:4] <- matrix(LETTERS[1:16], 4, 4, byrow = TRUE)
##' sM <- solveGame(M)
##' plot(sM)
##' @author Bill Venables
as.sudoku <- function(x, ...)
    UseMethod("as.sudoku")

##' Construct a Sudoku Game Object
##'
##' Coerce a matrix to an object that can be used as a sudoku game
##' @method as.sudoku matrix
##' @export
##' @title as.sudoku.matrix
##' @param x An n^2 x n^2 matrix
##' @param ... other arguments (currently ignored)
##' @return An object of class 'sudoku'
##' @author Bill Venables
as.sudoku.matrix <- function(x, ...) {
  n <- as.integer(round(sqrt(nrow(x))))
  if (nrow(x) != n^2 || !(n %in% 2:5))
      stop("invalid matrix")
  set <- if(n <= 3) as.character(1:(n^2)) else LETTERS[1:(n^2)]
  storage.mode(x) <- "character"
  is.na(x[!(x %in% set)]) <- TRUE
  structure(x, class = "sudoku")
}

##' Format a Date Relative to the Current Date
##'
##' Internal function used by fetchUKGame()
##' @title Format a Past Date
##' @param n A positive integer for how many days ago
##' @param warn Issue a warning if n <= 0 or n > 30
##' @return A character string of the form "dd/mm/yy"
##' @export daysAgo
##' @examples
##' daysAgo()  ## today
##' daysAgo(7) ## a week ago
##' @author Bill Venables
daysAgo <- function(n = 0, warn = TRUE) {
  if(warn && any(n > 30 | n < 0))
      warning("games for longer than 30 days ago are not retained.")
  then <- as.Date(strptime(date(), "%a %b %d %H:%M:%S %Y")) - as.integer(n)
  as.character(format(then, "%d/%m/%y"))
}

##' Retrieve a Sudoku Game
##'
##' Connects to http://www.sudoku.org.uk/DailySudoku.asp and retrieves
##' the sudoku game from 'day' days ago.  Based on a function from a
##' related sudoku package, sudoku::fetchSudokuUK with minor changes.
##' @title Retrieve a Sudoku from the UK Site
##' @param day positive integer < 30, how many days ago? or NULL for
##' the current day
##' @return The published sudoku game
##' @examples
##' \dontrun{
##' (g0 <- fetchUKGame())  ## today's game
##' (g3 <- fetchUKGame(3)) ## game from 3 days ago
##' }
##' @export fetchUKGame
##' @author Bill Venables
fetchUKGame <- function(day = NULL) {
  sudoku_UK <- "http://www.sudoku.org.uk/DailySudoku.asp"
  if(!is.null(day))
      sudoku_UK <- paste0(sudoku_UK, "?day=", daysAgo(day))
  con <- url(sudoku_UK)
  game <- readLines(con)
  close(con)
  game <- grep("^<td .*</td>$", game, value = TRUE)
  if(length(game) != 81)
      stop("No game found. Check the date?")
  game <- sub("^<td .*(.)</td>$", "\\1", game)
  as.sudoku(matrix(game, 9, 9, byrow = TRUE))
}

##' Construct a Random Sudoku Game
##'
##' Construcs a sudoku game for given n, 2 <= n <= 5.
##' n = 5 can be problematical.
##' @title Make a New Sudoku Game
##' @param n Size of the game, n^2 x n^2
##' @param gaps Number of holes to leave for the solution
##' @param maxit Number of tries before giving up.
##' @return a sudoku game
##' @export makeGame
##' @author Bill Venables
makeGame <- function(n = 3, gaps = ceiling(2*n^4/3), maxit = 5) {
  if(!missing(n) && (3 > n || n > 5))
      stop("Only cases n = 3, 4 or 5 are implemented. Sorry!")
  solved <- FALSE
  iter <- 0
  while(identical(solved, FALSE) && (iter <- iter+1) < maxit) 
      solved <- solveGame(seedGame(n))
  
  if(iter == maxit) stop("Maximum number of tries exceeded.")
  is.na(solved[sample(length(solved), gaps)]) <- TRUE
  solved
}

##' Plot a Sudoku Game
##'
##' Present a graphical display of a sudoku game and its solution if
##' the game is solved
##' @title Plot a Sudoku Game
##' @import graphics
##' @method plot sudoku
##' @export
##' @param x The sudoku game
##' @param ... additional arguments
##' @param cex Character expansion factor 
##' @param colSolution colour to be used for the solution (if present)
##' @param colGame colour to be used for the original game
##' @return NULL
##' @examples
##' set.seed(1234)
##' plot(solveGame(seedGame(4)))
##' @author Bill Venables
plot.sudoku <- function(x, ..., cex=2-(n-3)/2,
                        colSolution = "grey", colGame = "fire brick") {
  oldPar <- par(mar = rep(0, 4)+0.1, ...,
                xaxs = "i", xaxt = "n",
                yaxs = "i", yaxt = "n")
  on.exit(par(oldPar))
  n <- sqrt(nrow(x))
  xseq <- yseq <- 0:(n^2)
  plot(Y ~ X, data = expand.grid(X = xseq, Y = yseq), type = "n")
  abline(h = seq(0, n^2), v = seq(0, n^2), lty = "dotted", lwd = 0.5)
  abline(h = seq(0, n^2, by = n), v = seq(0, n^2, by = n), lwd=2)
  centres <- expand.grid(X = xseq[-1] - 0.5, Y = rev(yseq[-1]) - 0.5)
  game <- attr(x, "game")
  solved <- !is.null(game)
  with(centres, text(X, Y, t(x), cex = cex,
                     col = if(solved) colSolution else colGame,
                     font = if(solved) 1 else 2))
  if(solved) {
    with(centres, text(X, Y, t(game), cex = cex, col=colGame, font=2))
  }
  invisible()
}

##' Print a Sudoku Object
##'
##' Prints a sudoku object in an easily recognisable form.
##' @title Print a Sudoku Object
##' @method print sudoku
##' @export
##' @param x The sudoku game object
##' @param ... extra arguments (ignored) 
##' @return the object, invisibly
##' @author Bill Venables
print.sudoku <- function(x, ...) {
  n <- sqrt(nrow(x))
  y <- unclass(x)
  attr(y, "game") <- NULL
  y[is.na(y)] <- ""
  z <- "|"
  n2 <- 0
  for(j in 1:n) {
    n1 <- n2+1
    n2 <- n2+n
    z <- cbind(z, y[, n1:n2], "|")
  }
  y <- "-"
  n2 <- 0
  for(i in 1:n) {
    n1 <- n2+1
    n2 <- n2+n
    y <- rbind(y, z[n1:n2, ], "-")
  }
  i <- seq(1, (nc <- ncol(y)), n+1)
  y[i, i] <- "+"
  dimnames(y) <- list(rep("", nrow(y)), rep("", ncol(y)))
  print(y, quote = FALSE, ...)
  invisible(x)
}

##' Generate a random sudoku game starting point
##'
##' Generates a game with one instance of each symbol in random
##' positions.
##' @title Starting Point to Make a Random Sudoku Game
##' @param n Size of the game, n^2 x n^2
##' @return A sparse unsolved sudoku game
##' @export seedGame
##' @examples
##' set.seed(2345)
##' g <- seedGame(3)
##' sg <- solveGame(g) ## a completed random game
##' plot(sg)
##' @author Bill Venables
seedGame <- function(n = 3) {
  if(length(n) != 1 || !is.numeric(n) || n %% 1 != 0 || n < 2 | n > 5)
    stop("n must be a single integer between 2 and 5 inclusive")
  values <- if(n <= 3) as.character(1:(n^2)) else LETTERS[1:(n^2)]
  n2 <- n^2
  game <- matrix(NA_character_, n2, n2)

  game[sample(length(game), n2)] <- values
  structure(game, class = "sudoku")
}

##' Solve a Sudoku Game
##'
##' Given a sudoku game to be solved, find the solution.  IMPORTANT:
##' games are represented as n^2xn^2 character matrices, using 1-9 for
##' n=2 or 3, and LETTERS[1:(n^2)] for n = 4 or 5.
##' @title Solve a Sudoku Game
##' @param game The game to be solved
##' @param n The size of the game is n^2 x n^2
##' @return A solved sudoku game object if one found, or NULL if no
##' solution exists.
##' @examples
##' set.seed(1234)
##' (g <- makeGame(3))
##' (sg <- solveGame(g))
##' plot(sg)
##' @export
##' @author Bill Venables
solveGame <- function(game, n = as.integer(round(sqrt(nrow(game))))) {
  set <- if(n <= 3) {
    as.character(1:n^2)
  } else {
    LETTERS[1:n^2]
  }
  storage.mode(game) <- "character"
  is.na(game[!(game %in% set)]) <- TRUE
    
  nSet <- 1:(n^2)  ## work in integers
    
  toMatrix <- function(game) {  ## inverse of toArray
    game[] <- set[game]
    dim(game) <- c(n, n)^2
    game
  }
  
  toArray <- function(mat) {  ## inverse of toMatrix
    array(as.integer(match(mat, set)), dim = c(n,n,n,n))
  }
  
  conflict <- function(section) 
      any(duplicated(na.omit(as.vector(section))))
  
  invalid <- function(game) {
    for(i in 1:n) for(j in 1:n) {
      if(conflict(game[,i,,j]) ||  ## 'same block'
         conflict(game[i,j,,]) ||  ## 'same row'
         conflict(game[,,i,j]))    ## 'same column'
          return(TRUE)
    }
    FALSE
  }
    
  findSolution <- function(game) {
    if(invalid(game)) return(FALSE)
    
    while(anyNA(game)) {  ## anyNA() is only  in R 3.0.2 and later.
      holes <- which(is.na(game), arr.ind = TRUE)  ## a splendid trick!
      nr <- nrow(holes)
      fills <- vector("list", nr)
      lengths <- integer(nr)
      for(j in 1:nr) {
        i <- holes[j,]
        fills[[j]] <- setdiff(nSet,
                              c(game[    ,i[2],    ,i[4]],
                                game[i[1],i[2],    ,    ],
                                game[    ,    ,i[3],i[4]]))
        lengths[j] <- length(fills[[j]])
        if(lengths[j] == 0) return(FALSE)
      }
      if(any(h <- which(lengths == 1))) {
        game[holes[h,,drop = FALSE]] <- unlist(fills[h])
        if(invalid(game)) return(FALSE)
      } else {  ## only holes with multiple alternatives
        m <- which.min(lengths)
        entries <- fills[[m]]
        pos <- holes[m,,drop = FALSE]
        for(e in entries) {
          game[pos] <- e
          h <- findSolution(game)  ## recursive call
          if(!identical(h, FALSE)) return(h)
        }
        return(FALSE)  ## dud game, no solutions!
      }
    }
    game
  }
  
  ## the business starts here
  solution <- findSolution(toArray(game))
  if(identical(solution, FALSE)) NULL else
  structure(toMatrix(solution), game = game, class = "sudoku")
}

