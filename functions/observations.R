
read_observations = function(scientificname = "Halichoerus grypus", minimum_year = 1970,
                             remove_missing = c("eventDate", "year", "individualCount"),
                             ...){
  
  #' Read raw OBIS data and then filter it
  #' 
  #' @param scientificname chr, the name of the species to read
  #' @param minimum_year num, the earliest year of observation to accept or 
  #'   set to NULL to skip
  #' @param ... other arguments passed to `read_obis()`
  #' @return a filtered table of observations
  
  # Happy coding!
  
  # read in the raw data
  x = read_obis(scientificname, ...) |>
    dplyr::mutate(month = factor(month, levels = month.abb))
  
  # if the user provided a non-NULL filter by year
  if (!is.null(minimum_year)){
    x = x |>
      filter(year >= minimum_year)
  }

  if ("eventDate" %in% remove_missing){
    x = x |> filter(!is.na(eventDate))
  }
  if ("year" %in% remove_missing){
    x = x |> filter(!is.na(eventDate))
  }
  if ("individualCount" %in% remove_missing){
    x = x |> filter(!is.na(eventDate))
  }
  
  return(x)
  
  
}
#source("setup.R")
#obs = read_observations()
#summary(obs)
#