## Functions for the epiDataWorld package

lookup_level <- function(level){
  
  if(is.character(level)){
    
    if(level == "Country"){
      level_int = 1
    } else if (level == "State"){
      level_int = 2
    } else if (level == "Lower"){
      level_int = 3
    }
    
  } else {
    
    stop("Level should be of type character")
    
  }
  
  return(level_int)
  
}