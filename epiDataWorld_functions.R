## Functions for the epiDataWorld package

lookup_level <- function(level){
  
  if(is.character(level)){
    
    if(grepl("Country", level,  fixed = TRUE)){
      level_int = 1
    } else if (grepl("State", level,  fixed = TRUE)){
      level_int = 2
    } else if (grepl("Lower", level,  fixed = TRUE)){
      level_int = 3
    }
    
  } else {
    
    stop("Level should be of type character")
    
  }
  
  return(level_int)
  
}

rollback <- function(df, column){
  
  if(is.data.frame(df)){
  
    df[[column]] <- df[[column]] - lag(df[[column]])
    df[[column]][is.na(df[[column]])] <- 0
    
  } else {
    
    stop("df should be of type data.frame")
    
  }
  
  return(df)
  
}
